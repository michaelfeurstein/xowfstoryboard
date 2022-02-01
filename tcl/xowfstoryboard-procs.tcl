namespace eval ::xowfstoryboard {

  ::xo::PackageMgr create ::xowfstoryboard::Package \
      -package_key "xowfstoryboard" \
	  -pretty_name "Storyboard Editor" \
      -superclass ::xowf::Package

  Package instproc initialize {} {
        ns_log notice "++++ CALL ::xowfstoryboard::initialize"
        next
  }

  Package site_wide_package_parameter_page_info {
    name en:xowf-site-wide-parameter
    title "Xowf Site-wide Parameter"
    instance_attributes {
      index_page table-of-contents
      MenuBar t
      top_includelet none
      production_mode t
      with_user_tracking t with_general_comments f with_digg f with_tags f
      with_delicious f with_notifications f
      security_policy ::xowiki::policy1
  }}

  Package site_wide_package_parameters {
    parameter_page en:xowf-site-wide-parameter
  }

  Package site_wide_pages {
	monaco.form

	storyboard.wf
	experiment.wf
	storyboard.form
	experiment_landing.form
	experiment_summary.form
	storyboard_test.form
  }

  Package default_package_parameter_page_info {
    name en:xowf-default-parameter
    title "Xowf Default Parameter"
    instance_attributes {
      MenuBar t top_includelet none production_mode t with_user_tracking t with_general_comments f
      with_digg f with_tags f
      ExtraMenuEntries {{clear_menu -menu New} {entry -name New.Storyboard -label {#xowfstoryboard.menu-New-Storyboard#} -form en:storyboard.wf}}
      with_delicious f with_notifications f security_policy ::xowiki::policy1
    }
  }

  ad_proc time_elapsed {object} {
	set item_id [$object item_id]
	$object set_property -new 1 time_elapsed [::xo::dc get_value calc_elapsed {
		select current_timestamp - min(o.creation_date) from xowiki_form_page f, cr_revisions r, acs_objects o where f.xowiki_form_page_id = r.revision_id and r.revision_id = o.object_id and f.state = 'editing' and r.item_id = :item_id
	}]

	#
	# get all the timestamps for this item
	#
	#set results [::xo::dc list_of_lists get_data [subst {
    #  select o.creation_date, r.revision_id = i.live_revision as is_live, f.state from cr_revisions r, acs_objects o, xowiki_form_page f, cr_items i where o.object_id = r.revision_id and f.xowiki_form_page_id = r.revision_id and i.item_id = [$object item_id] and r.item_id = i.item_id order by o.creation_date asc
	#}]]
	#
	#foreach e $results {
	#	ns_log notice "e:$e"
	#}
  }

  ad_proc hello {} {
	ns_log notice "this is a text"
	return "This is a TEST"
  }
}
