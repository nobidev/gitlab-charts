#!/usr/bin/env bash
set -euo pipefail

# Script to manage localized documentation verification and testing
# Usage:
#   ./docs_i18n_verify.sh --verify-paths    # Check if all localized files have English originals
#   ./docs_i18n_verify.sh --check-links     # Create temp directory with symlinks and run lychee

readonly DOC_DIR="doc"
readonly LOCALE_BASE_DIR="doc-locale"
readonly LOCALE_PATH_REGEX="^doc-locale/[^/]+/(.+)$"

# Utility functions
log_info() { echo "$@"; }
log_error() { echo "$@" >&2; }
log_success() { echo -e "\n✅ $*"; }
log_failure() { echo -e "\n❌ $*" >&2; }

validate_directories() {
    local missing_dirs=()
    [[ ! -d "$DOC_DIR" ]] && missing_dirs+=("$DOC_DIR")
    [[ ! -d "$LOCALE_BASE_DIR" ]] && missing_dirs+=("$LOCALE_BASE_DIR")
    
    if [[ ${#missing_dirs[@]} -gt 0 ]]; then
        log_error "Error: Required directories not found: ${missing_dirs[*]}"
        exit 1
    fi
}

show_help() {
    cat << EOF
Usage: $0 [OPTION]

Options:
  --verify-paths    Check if all localized files have English originals
  --check-links     Create temp directory with symlinks and run lychee
  --help, -h        Show this help message

Examples:
  $0 --verify-paths
  $0 --check-links
EOF
}

print_error_report() {
    local title="$1"
    local -n items=$2
    local description="$3"
    
    log_failure "$title: Found ${#items[@]} issues."
    log_error "===== ${title^^} ====="
    [[ -n "$description" ]] && log_error "$description"
    
    for item in "${items[@]}"; do
        log_error "  - $item"
    done
    log_error "=========================="
}

verify_orphaned_paths() {
    log_info "Checking if localized documentation files have matching English originals..."
    
    local failed_routes=()
    local unexpected_paths=()
    local failed=0

    while IFS= read -r -d '' locale_file; do
        if [[ "$locale_file" =~ $LOCALE_PATH_REGEX ]]; then
            local file_path="${BASH_REMATCH[1]}"
            local original_file="$DOC_DIR/$file_path"
            
            if [[ ! -f "$original_file" ]]; then
                log_error "Error: Original English file does not exist: $original_file"
                log_error "For localized file: $locale_file"
                failed_routes+=("$original_file → $locale_file")
                failed=1
            else
                log_info "Verified: $locale_file → $original_file"
            fi
        else
            log_error "Warning: Unexpected path format: $locale_file"
            unexpected_paths+=("$locale_file")
        fi
    done < <(find "$LOCALE_BASE_DIR" -type f -name "*.md" -print0)

    # Report errors in order of severity
    if [[ ${#unexpected_paths[@]} -gt 0 ]]; then
        print_error_report "PATH FORMAT VERIFICATION FAILED" unexpected_paths \
            "Expected: doc-locale/<language_code>/<path>"
        log_error "Please ensure all files follow the expected directory structure."
        exit 2
    fi

    if [[ $failed -ne 0 ]]; then
        print_error_report "PATH VERIFICATION FAILED" failed_routes \
            "MISSING ENGLISH PATH => LOCALIZED VERSION"
        log_error "Please ensure all localized content has corresponding English files."
        exit 1
    fi

    log_success "Verification successful! All localized files have matching English originals."
}

setup_temp_directory() {
    local script_dir project_dir timestamp
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    project_dir="$(dirname "$script_dir")"
    timestamp=$(date +%Y%m%d_%H%M%S)
    
    TEMP_DIR="$project_dir/lychee_test_$timestamp"
    mkdir -p "$TEMP_DIR"
    log_info "Created temporary directory: $TEMP_DIR"
}

cleanup_temp_directory() {
    if [[ -n "${TEMP_DIR:-}" && -d "$TEMP_DIR" ]]; then
        log_info "Cleaning up temporary directory: $TEMP_DIR"
        rm -rf "$TEMP_DIR"
    fi
    
    # Only remove temp base directory if it's specifically our created temp directory pattern
    local temp_base="${TEMP_DIR%/*}"
    if [[ -d "$temp_base" && "$temp_base" =~ lychee_test_ && -z "$(ls -A "$temp_base" 2>/dev/null)" ]]; then
        rmdir "$temp_base"
    fi
}

create_symlinks_for_locale() {
    local locale_dir="$1"
    local locale_name
    locale_name=$(basename "$locale_dir")
    log_info "Processing locale: $locale_name"
    
    (
        cd "$DOC_DIR" || exit 1
        find . -type f -name "*.md" | while read -r file; do
            local source_file target_dir target_file
            source_file="$(pwd)/$file"
            target_dir="$locale_dir/$(dirname "$file")"
            target_file="$locale_dir/$file"
            
            # Create symlink if file doesn't exist or is already a symlink
            if [[ ! -f "$target_file" || -L "$target_file" ]]; then
                [[ -L "$target_file" ]] && rm "$target_file"
                mkdir -p "$target_dir"
                ln -s "$source_file" "$target_file"
                log_info "  Created symlink: $file"
            fi
        done
    )
}

check_links() {
    # Comment out to see directory created for lychee test
    trap cleanup_temp_directory EXIT
    
    validate_directories
    setup_temp_directory
    
    # Create temporary locale base directory and copy content
    local temp_locale_base
    temp_locale_base="$TEMP_DIR/$(basename "$LOCALE_BASE_DIR")"
    mkdir -p "$temp_locale_base"
    
    log_info "Copying locale directories to temporary location..."
    if ! cp -r "$LOCALE_BASE_DIR"/* "$temp_locale_base/" 2>/dev/null; then
        log_info "No locale files found to copy (this is normal if doc-locale is empty)"
    fi

    # Process each locale directory
    for locale_dir in "$temp_locale_base"/*; do
        [[ -d "$locale_dir" ]] && create_symlinks_for_locale "$locale_dir"
    done

    log_info "Running lychee on temporary directory..."
    lychee --offline --include-fragments "$temp_locale_base"
}

# Main script logic
main() {
    case "${1:-}" in
        --verify-paths)
            verify_orphaned_paths
            ;;
        --check-links)
            check_links
            ;;
        --help|-h)
            show_help
            ;;
        "")
            log_error "Error: No argument provided"
            show_help
            exit 1
            ;;
        *)
            log_error "Error: Unknown argument '$1'"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
