#
# Make sure, the site-wide pages are loaded, and refetch pages, when
# the source code in the prototype pages changes.
#
try {
  ::xowfstoryboard::Package require_site_wide_pages -refetch_if_modified true
} on error {errorMsg} {
  ns_log error "xowfstoryboard-init:  require_site_wide_pages lead to: $errorMsg"
}

# local-only resources

template::register_urn \
    -urn      urn:ad:css:xowfstoryboard:storyboard \
    -resource /resources/xowfstoryboard/storyboard.css
