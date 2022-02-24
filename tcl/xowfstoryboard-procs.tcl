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

	treatment1
	treatment2
	treatmenttest1
	treatmenttest2
	treatmenttutorial

	reference_kv_video
	reference_kv_timestamp
	reference_kv_textpage
	reference_kv_module
	reference_kv_question

	reference_nl_video
	reference_nl_timestamp
	reference_nl_textpage
	reference_nl_module
	reference_nl_question
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
  # get treatment reference from db
  # and set the property of object to it
  #
  # a treatment is an ::xowiki::Page
  # with text containing instructions for a treatment
  #
  # the treatment pages are called:
  # - en:treatment1.page
  # - en:treatment2.page
  #

  ad_proc set_instruction_content {object treatment} {
	set treatment_name "en:treatment$treatment"
	set treatment_page_item_id [::xo::dc get_value t_id {select item_id from xowiki_page_live_revision where name = :treatment_name}]
	set treatment_page [::xo::db::CrClass get_instance_from_db -item_id $treatment_page_item_id]
	set htmlInstruction [lindex [$treatment_page set text] 0]
	$object set_property -new 1 instruction $htmlInstruction
  }

  #
  # calculate elapsed time
  #
  # do this via SQL:
  #	current timestamp - the earliest state of editing timestamp (right after the user clicked start)
  #
  # time_elapsed = editing time on storyboard
  #

  ad_proc time_elapsed {object} {
	set item_id [$object item_id]
	set time_elapsed [::xo::dc get_value calc_elapsed {
		select current_timestamp - min(o.creation_date) from xowiki_form_page f, cr_revisions r, acs_objects o where f.xowiki_form_page_id = r.revision_id and r.revision_id = o.object_id and f.state = 'editing' and r.item_id = :item_id
	}]
	set trimmed [string range $time_elapsed 0 7]
	$object set_property -new 1 time_elapsed $trimmed

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

  ad_proc set_help_content {object notation} {
	# pseudo approach:
	# for each xowiki::Page starting with reference_xxx
	# generate button and modal
	# place inside help_content

	namespace import ::StoryBoard::*

	set help_content ""

	if {$notation eq "key-value"} {
		set reference_prefix "en:reference_kv_"

	} elseif {$notation eq "natural-language"} {
		set reference_prefix "en:reference_nl_"
	}

	set storyboard_elements [Helper getStoryboardElements]

	foreach element $storyboard_elements {
		set page_name "$reference_prefix$element"
		set page_id [::xo::dc get_value p_id {select item_id from xowiki_page_live_revision where name = :page_name}]
		if {$page_id eq ""} {
			ns_log notice "page $element not found --> continue"
			continue
		}
		set reference_page [::xo::db::CrClass get_instance_from_db -item_id $page_id]
		set reference_html_text [lindex [$reference_page set text] 0]
		set reference_html_button_title [$reference_page set description]
		set reference_html_title [$reference_page set title]

		set data_target_a "$element"
		set data_target_b "Modal"
		set data_target "$data_target_a$data_target_b";# --> e.g.: videoModal

		set aria_labelledby_b "Label"
		set aria_labelledby "$data_target$aria_labelledby_b";# --> e.g.: videoModalLabel

		set btn_id_a $element
		set btn_id_b "-btn"
		set btn_id "$btn_id_a$btn_id_b";# --> e.g.: video-btn

		append help_content [subst -nocommands {

			<a id="$btn_id-popover" tabindex="0" class="helperbtn btn btn-info" role="button" data-placement="bottom">$reference_html_button_title</a>

			<div id="$btn_id-popover-content" class="hidden">
				<div>
				$reference_html_text
				</div>
			</div>

			<div id="$btn_id-popover-title" class="hidden">
				<div>
					$reference_html_title
				</div>
			</div>

			<script>
				\$(function(){
					// Enables popover
					\$("#$btn_id-popover").popover({
					template : reftemplate,
						html : true,
						content: function() {
							return \$("#$btn_id-popover-content").html();
						},
						title: function() {
							return \$("#$btn_id-popover-title").html();
						}
					});
				});
			</script>
		}]
	};# --> foreach end

	# append js call to prevent copy inside popover content / doesn't work yet - css does the jobs
	# keeping for reference
	#
	#append help_content [subst -novariables -nocommands {
	#	<script>
	#	$(function(){
	#		$(".ref-body.popover-content").bind('cut copy', function(e) {
	#			console.log("prevented");
    #		e.preventDefault();
    #        });
	#	});
	#	</script>
	#}]

	$object set_property -new 1 helpers $help_content
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

  ad_proc test_content {param} {
	set result "Some text \nother text \n stuff $param"
	return [ad_text_to_html $result]
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
