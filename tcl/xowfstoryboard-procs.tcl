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
	ns_log notice "++++ ::xowfstoryboard::initialize"
	::xo::Page requireCSS urn:ad:css:xowfstoryboard:storyboard
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

	treatmentperiod1
	treatmentperiod2
	treatmenttest1
	treatmenttest2
	treatmenttutorial

	reference_kv_video
	reference_kv_timestamp
	reference_kv_textpage
	reference_kv_module
	reference_kv_question

	reference_nl_create
	reference_nl_set
	reference_nl_add

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
  # - en:treatmentperiod1.page
  # - en:treatmentperiod2.page
  #

  ad_proc set_instruction_content {object treatment} {
	set treatment_name "en:treatment$treatment"
	set treatment_page_item_id [::xo::dc get_value t_id {select item_id from xowiki_page_live_revision where name = :treatment_name}]
	set treatment_page [::xo::db::CrClass get_instance_from_db -item_id $treatment_page_item_id]
	set htmlInstruction [lindex [$treatment_page set text] 0]

	# add js to initialize jScrollPane
	append htmlInstruction [subst -nocommands -novariables {
		<script>
			$(function () {

				var settings = {
					showArrows: false,
					autoReinitialise: true
				};

			var pane = $('.sb-instruction')
			pane.jScrollPane(settings);

			});
		</script>
	}]

	$object set_property -new 1 instruction $htmlInstruction
  }

  #
  # calculate elapsed time
  #
  # do this via SQL:
  #	current timestamp - the earliest state of editing timestamp (right after the user clicked start)
  #
  # time_elapsed = editing time on storyboard based on latest editing revision
  #

  ad_proc time_elapsed {object} {
	set item_id [$object item_id]
	set time_elapsed [::xo::dc get_value calc_elapsed {
		select current_timestamp - min(o.creation_date) from xowiki_form_page f, cr_revisions r, acs_objects o where f.xowiki_form_page_id = r.revision_id and r.revision_id = o.object_id and f.state = 'editing' and r.item_id = :item_id
	}]
	set trimmed [string range $time_elapsed 0 7]
	return $trimmed
  }

  #
  # setup helpers content
  #
  # generate html for helpers field displaying
  # list of buttons with reference popovers
  # natural-language has slightly different pages
  # than key-value
  #

  ad_proc set_help_content {object notation} {
	# pseudo approach:
	# for each xowiki::Page starting with reference_xxx
	# generate button and modal
	# place inside help_content

	namespace import ::StoryBoard::*

	set help_content ""
	set storyboard_elements [Helper getStoryboardElements]

	if {$notation eq "key-value"} {
		set reference_prefix "en:reference_kv_"

		append help_content [subst {<b>Commands:</b><br>}]
		append help_content [generate_buttons $storyboard_elements $reference_prefix]
	} elseif {$notation eq "natural-language"} {
		set syntax_nl_keywords [Helper getNaturalLanguageKeywords]
		set reference_prefix "en:reference_nl_"

		append help_content [subst {<b>Commands:</b><br>}]
		append help_content [generate_buttons $syntax_nl_keywords $reference_prefix]
		append help_content [subst {<br><br><b>Element Types:</b><br>}]
		append help_content [generate_buttons $storyboard_elements $reference_prefix]
	}

	append help_content [subst -novariables -nocommands {
		<script>
			$(function() {
					$(document).on("click", ".popover .close" , function(){
						//console.log("closing");
						$(this).parents(".popover").popover('hide');
					});
			});

			document.onkeydown = function(evt) {
				evt = evt || window.event;
				var isEscape = false;
				if ("key" in evt) {
					isEscape = (evt.key === "Escape" || evt.key === "Esc");
				} else {
					isEscape = (evt.keyCode === 27);
				}
				if (isEscape) {
					//console.log("closing via esc key");
					$('[data-toggle="popover"]').popover('hide');
				}
			};
		</script>
	}]

	$object set_property -new 1 helpers $help_content
  }

  #
  # generate popover buttons
  #
  # the buttons with respective content are generated
  # based on ::xowiki::Pages and their content
  # using popovers with no copy paste feature and they
  # stay open for easier referencing
  #
  # elements: list of classes in sync with pages
  # prefix: e.g.: reference_nl / reference_kv
  #

  ad_proc generate_buttons {storyboard_elements reference_prefix} {
		set help_content ""

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

			set btn_id_a $element
			set btn_id_b "-btn"
			set btn_id "$btn_id_a$btn_id_b";# --> e.g.: video-btn

			# create the helper buttons
			#
			# notes:
			# javascript 'reftemplate' variable is defined inside www/resources/popover-template.js
			append help_content [subst -nocommands {

				<a id="$btn_id-popover" tabindex="0" class="helperbtn btn btn-info" role="button" data-placement="bottom" data-toggle="popover">$reference_html_button_title</a>

				<div id="$btn_id-popover-content" class="hidden">
					<div>
					$reference_html_text
					</div>
				</div>

				<div id="$btn_id-popover-title" class="hidden">
					<div>
						$reference_html_title <span class="tip">(key: esc)</span> <a class="close" data-dismiss="popover">&times;</a>
					</div>
				</div>

				<script>
					\$(function(){
						// Enables popover
						// retemplate variable is defined inside www/resources/popover-template.js
						\$("#$btn_id-popover").popover({
							template : reftemplate,
							trigger: 'manual',
							html : true,
							content: function() {
								return \$("#$btn_id-popover-content").html();
							},
							title: function() {
								return \$("#$btn_id-popover-title").html();
							}
						});

						\$("#$btn_id-popover").click(function (e) {
							//console.log("toggling $btn_id");

							e.preventDefault();

							if (\$("#$btn_id-popover").next('div.popover:visible').length) {
								// popover is visible
								\$('[data-toggle="popover"]').popover('hide');
							} else {
								// popover is not visible
								\$(this).popover('toggle');
							}

							// hide all othe popovers
							\$('[data-toggle="popover"]').not(this).popover('hide');

						});
					});

				</script>
			}]
		};# --> foreach end

		return $help_content
  }

  #
  # check storyboard
  #
  # either "run" or "validate" storyboard
  # this proc is used to run the storyboard and either
  # return 0/1 for simple validation if it worked
  # or return list of infos to work with
  #
  # run
  # returns list with storyboard_status & html
  #
  # validate
  # returns 0/1
  #

  ad_proc check_storyboard {sb n mode} {
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
	#ns_log notice "--- check_storyboard sb:$storyboard"
	#ns_log notice "--- check_storyboard notation:$notation"

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

		if {$mode eq "run"} {
			set visitor [HTMLVisitor new]
			set htmlResult [$visitor evaluate $module]
		}
	} on error {msg} {
		ns_log notice "--- check_storyboard mode:$mode status:0\n\nmsg:\n$msg"
		if {$mode eq "run"} {
			return [list storyboard_status 0 html $msg]
		} elseif {$mode eq "validate"} {
			return 0
		}
	} on ok {msg} {
		ns_log notice "--- check_storyboard mode:$mode status:1"
		if {$mode eq "run"} {
			return [list storyboard_status 1 html [$htmlResult asHTML]]
		} elseif {$mode eq "validate"} {
			return 1
		}
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

}
