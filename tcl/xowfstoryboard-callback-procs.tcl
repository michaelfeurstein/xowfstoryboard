namespace eval ::xowfstoryboard {

  ad_proc -private after-instantiate {-package_id:required } {
    Callback when this an xowf instance is created
  } {
    ns_log notice "++++ BEGIN ::xowfstoryboard::after-instantiate -package_id $package_id"

    #
    # Create a parameter page for convenience
    #
    ::xowfstoryboard::Package configure_fresh_instance \
        -package_id $package_id \
        -parameters [::xowf::Package default_package_parameters] \
        -parameter_page_info [::xowfstoryboard::Package default_package_parameter_page_info]

    ns_log notice "++++ END ::xowfstoryboard::after-instantiate -package_id $package_id"
  }
}
