::xo::library require -package xowfstoryboard storyboard-language/error_handler
::xo::library require -package xowfstoryboard storyboard-language/language_model
::xo::library require -package xowfstoryboard storyboard-language/parser
::xo::library require -package xowfstoryboard storyboard-language/visitor
::xo::library require -package xowfstoryboard storyboard-language/worker
::xo::library require -package xowfstoryboard storyboard-language/expression_builder
::xo::library require -package xowfstoryboard storyboard-language/definition_builder
::xo::library require -package xowfstoryboard storyboard-language/step_definitions

namespace eval ::xowfstoryboard {

  ::xo::PackageMgr create ::xowfstoryboard::Package \
      -package_key "xowfstoryboard" \
	  -pretty_name "Storyboard Editor" \
      -superclass ::xowf::Package

  Package instproc initialize {} {
        ns_log notice "++++ CALL ::xowfstoryboard::initialize"
		am_i_admin
		setup_experiment_policy
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
	  template_file view-xowfstoryboard
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
      with_delicious f with_notifications f security_policy ::xowiki::policy1 template_file view-xowfstoryboard
    }
  }

  #
  # Policy
  #

  ad_proc setup_experiment_policy {} {
	::xowiki::policy1 copy ::xowfstoryboard::experiment-policy

	::xowfstoryboard::experiment-policy contains {
	  Class create FormPage -array set require_permission {
		edit		public
		view		public
	  }
	}
  }

  #
  # check if we are admin
  # set value accordingly
  # this value is used inside resources/templates/view-xxx.adp
  #

  ad_proc am_i_admin {} {
	set package_id [::xo::cc set package_id]
    set amiadmin [permission::permission_p \
                      -party_id [::xo::cc user_id] \
                      -object_id $package_id \
                      -privilege "admin"]
	set ::xowfstoryboard::am_i_admin $amiadmin
  }

  #
  # calculate elapsed time
  #
  # do this via SQL:
  # 	current timestamp - the earliest state of editing timestamp (right after the user clicked start)
  #
  # time_elapsed = editing time on storyboard
  #

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

  # TODO: find out how this can work
  Class create StoryboardHandler -ad_doc {
	a handler to store results from storyboard
  } -parameter {
	{storyboard_ok 0}
  }

  StoryboardHandler instproc is_sb_ok {} {
	return :storyboard_ok
  }

  StoryboardHandler instproc hello {} {
	ns_log notice "hello from StoryboardHandler"
  }

  ad_proc check_storyboard {sb n} {
	set storyboard [fromBase64 $sb]
	set notation $n

	namespace import ::StoryBoard::*

	# destroy all instances of type Element
	# in order to prevent accumulation of zombie modules
	foreach i [StoryBoard::Element info instances -closure] {
		$i destroy
	}

	# ad_log for full stack logging
	# ns_log for "just a message"
	ns_log notice "--- check_storyboard sb:$storyboard"
	ns_log notice "--- check_storyboard notation:$notation"

	try {
		set internalBuilder [StoryboardBuilder new -notation $notation]

		if {$notation eq "key-value"} {
			# kv
			set internalParser [StoryboardParser new -storyboard $storyboard]
			set module [$internalBuilder from [$internalParser storyboardDict get]]
		} elseif {$notation eq "natural-language"} {
			# nl
			set dictBuilder [StepDefinitions setup]
			set storyboardDict [$dictBuilder get $storyboard]
			set module [$internalBuilder from $storyboardDict]
		}

		set visitor [HTMLVisitor new]
		set htmlResult [$visitor evaluate $module]
	} on error {msg} {
		ad_log notice "--- check_storyboard msg:\n$msg"
		return [list storyboard_status 0 html $msg]
	} on ok {msg} {
		return [list storyboard_status 1 html [$htmlResult asHTML]]
	}
  }

  ad_proc fromBase64 {encValue} {
        ns_log notice "++++ monaco fromBase64 encValue:$encValue"
    # this is the equivalent to b64_to_utf8 at the client side
    if {$encValue ne ""} {
          ns_log notice "++++ monaco fromBase64 return:[encoding convertfrom utf-8 [binary decode base64 $encValue]]"
      return [encoding convertfrom utf-8 [binary decode base64 $encValue]]
    }
  }

  #
  # MIXIN EXAMPLE
  #
  # begin
  #

  # Class create StoryboardMixin
  #
  #
  # set property via double save approach
  #
  #  StoryboardMixin instproc save args {
  #	set item_id ${:item_id}
  #	set db_state_before [db_string query {select state from xowiki_form_instance_item_index where item_id = :item_id}]
  #	ns_log warning "before ${:state} ${:item_id} $db_state_before"
  #	next
  #	if {![info exists :__saved_p] && ${:state} eq "finished"} {
  #		set :__saved_p 1
  #		:set_property -new 1 time_elapsed [::xo::dc get_value calc_elapsed {
  #			select (select o.creation_date from acs_objects o, cr_items i where o.object_id = i.live_revision and i.item_id = :item_id) - (select min(o.creation_date) from xowiki_form_page f, cr_revisions r, acs_objects o where f.xowiki_form_page_id = r.revision_id and r.revision_id = o.object_id and f.state = 'editing' and r.item_id = :item_id)
  #		}]
  #		:save
  #	}
  #	ns_log warning "after ${:state} ${:item_id}"
  #  }


  # StoryboardMixin instproc save args {
  #	ns_log warning "before ${:state} ${:item_id}"
  #	set item_id ${:item_id}
  #	if {${:state} eq "finished"} {
  #		:set_property -new 1 time_elapsed [::xo::dc get_value calc_elapsed {
  #			select current_timestamp - min(o.creation_date) from xowiki_form_page f, cr_revisions r, acs_objects o where f.xowiki_form_page_id = r.revision_id and r.revision_id = o.object_id and f.state = 'editing' and r.item_id = :item_id
  #			}]
  #		}
  #	ns_log warning "before next"
  #	next
  #	ns_log warning "after next ${:state} ${:item_id}"
  #}
  #
  #
  # EXAMPLE END

}
