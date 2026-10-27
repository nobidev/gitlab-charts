#!/usr/bin/env ruby

# Verifies that every CNG image the chart actually renders exists in the
# registry.
#
# This guards against a component version bump (for example a Renovate MR)
# merging before CNG has published the corresponding image. Without this check
# the bad state is invisible until a real deploy hits ImagePullBackOff.
#
# Rather than parse the values files, this reads a rendered manifest
# (`helm template ...`) and checks every `image:` the chart would actually
# deploy. That covers images pulled in through subchart `appVersion`s and
# optional subcharts, not just literal tags written into a values.yaml.
#
# See https://gitlab.com/gitlab-org/charts/gitlab/-/work_items/6733
#
# Usage:
#   helm template . -f settings.yaml | ruby scripts/ci/verify_component_image_tags.rb
#   ruby scripts/ci/verify_component_image_tags.rb rendered.yaml
#
# Image existence is checked with skopeo, which handles registry auth tokens
# and the various manifest media types for us.

require 'yaml'
require 'set'
require 'open3'

class ImageTagVerifier
  # Raised when an image cannot be verified (authentication or an otherwise
  # unexpected error), so a misconfiguration is never silently reported as a
  # missing image.
  VerificationError = Class.new(StandardError)

  # Only check images we publish ourselves. Third-party images (nginx, redis,
  # postgres, ...) are out of scope.
  CNG_PREFIX = 'registry.gitlab.com/gitlab-org/build/cng/'.freeze

  # Floating streams rebuilt on every pipeline, validated elsewhere
  # (pin_image_digests.sh on the default branch). Here we only care about
  # pinned release tags such as `v4.43.0-gitlab`.
  SKIP_TAGS = %w[master main].freeze

  # Registry lookups are occasionally flaky; retry transient failures before
  # treating a result as authoritative.
  MAX_ATTEMPTS = 3
  RETRY_BASE_DELAY = 2

  def initialize(manifest:, out: $stdout, err: $stderr)
    @manifest = manifest
    @out = out
    @err = err
  end

  # Entry point. Returns a process exit status (0 ok, 1 missing image).
  def run
    login_registry
    refs = collect_refs(@manifest)

    if refs.empty?
      @out.puts 'No pinned CNG image tags to verify.'
      return 0
    end

    missing = []
    refs.sort.each do |ref|
      present = image_present?(ref)
      @out.puts(format('%-7s %s', present ? 'ok' : 'MISSING', ref))
      missing << ref unless present
    end

    return 0 if missing.empty?

    @err.puts
    @err.puts 'The following image tags are referenced by the chart but do not exist:'
    missing.each { |ref| @err.puts "  #{ref}" }
    @err.puts
    @err.puts 'A chart bump likely merged ahead of the image being published.'
    1
  rescue VerificationError => e
    @err.puts
    @err.puts "Unable to verify image tags: #{e.message}"
    1
  end

  # Parses the rendered manifest and returns the unique, in-scope image refs.
  def collect_refs(manifest)
    refs = Set.new
    YAML.load_stream(manifest) do |doc|
      image_values(doc).each { |ref| refs << ref if check?(ref) }
    end
    refs.to_a
  rescue Psych::Exception => e
    raise VerificationError, "failed to parse rendered manifest: #{e.message}"
  end

  # Recursively collects every string value stored under an "image" key, which
  # is how container and initContainer images appear in a rendered manifest.
  def image_values(node)
    case node
    when Hash
      found = []
      found << node['image'] if node['image'].is_a?(String)
      found + node.values.flat_map { |value| image_values(value) }
    when Array
      node.flat_map { |value| image_values(value) }
    else
      []
    end
  end

  # True when a ref is a pinned CNG image worth checking.
  def check?(ref)
    return false unless ref.start_with?(CNG_PREFIX)
    # A digest-pinned ref (with or without a tag) is immutable, so always verify
    # it rather than trying to classify its tag.
    return true if digest_pinned?(ref)

    tag = image_tag(ref)
    return false if tag.nil?
    return false if SKIP_TAGS.include?(tag)
    return false if tag.include?('-stable')

    true
  end

  # True when the ref pins a digest, e.g. "repository@sha256:..." or
  # "repository:tag@sha256:...".
  def digest_pinned?(ref)
    ref.include?('@')
  end

  # Extracts the tag from a "repository:tag" ref, or nil when no tag is present.
  # A digest suffix is stripped first; rpartition keeps a registry host port
  # intact.
  def image_tag(ref)
    name = ref.split('@', 2).first
    repo, separator, tag = name.rpartition(':')
    return nil if separator.empty? || repo.empty?

    tag
  end

  # Authenticates against the registry when a token is available, mirroring
  # wait_for_images.sh and pin_image_digests.sh. The CNG registry currently
  # allows anonymous reads, so this is best-effort: a login failure is logged
  # but not fatal.
  def login_registry
    password = ENV['CNG_REGISTRY_PASSWORD'] || ENV['CI_JOB_TOKEN']
    return if password.to_s.empty?

    username = ENV['CNG_REGISTRY_USERNAME'] || 'gitlab-ci-token'
    _out, err, status = Open3.capture3(
      'skopeo', 'login', '--username', username, '--password-stdin', registry_host,
      stdin_data: password
    )
    return if status.success?

    @err.puts "skopeo login to #{registry_host} failed (continuing anonymously): #{err.strip}"
  end

  # Returns true if the image exists, false if it is genuinely absent. Retries
  # transient failures, and raises VerificationError on an authentication or
  # otherwise unexpected error so a misconfiguration never masquerades as a
  # missing image and silently blocks merges.
  def image_present?(ref)
    attempt = 0

    loop do
      attempt += 1
      ok, output = skopeo_inspect(ref)
      return true if ok
      # Check auth first so an authentication failure is never swallowed as a
      # missing image.
      raise VerificationError, "#{ref}: #{output.strip}" if auth_error?(output)
      return false if not_found?(output)
      raise VerificationError, "#{ref}: #{output.strip}" if attempt >= MAX_ATTEMPTS

      sleep(RETRY_BASE_DELAY * (2**(attempt - 1)))
    end
  end

  # Runs `skopeo inspect`; returns [success?, combined stdout+stderr]. Separated
  # so specs can stub the registry call.
  def skopeo_inspect(ref)
    out, err, status = Open3.capture3('skopeo', 'inspect', '--raw', "docker://#{ref}")
    [status.success?, "#{out}#{err}"]
  end

  # Matches skopeo's "not found" errors. HTTP codes use word boundaries so an
  # incidental digit run (a digest fragment, a port, "401ms") is not matched.
  def not_found?(output)
    output.match?(/manifest unknown|name unknown|not found|\b404\b/i)
  end

  # Matches skopeo's authentication/authorization errors.
  def auth_error?(output)
    output.match?(/unauthorized|forbidden|authentication required|access to the resource is denied|\b40[13]\b/i)
  end

  def registry_host
    CNG_PREFIX.split('/', 2).first
  end
end

if $0 == __FILE__
  manifest = ARGV.empty? ? $stdin.read : File.read(ARGV[0])
  exit ImageTagVerifier.new(manifest: manifest).run
end
