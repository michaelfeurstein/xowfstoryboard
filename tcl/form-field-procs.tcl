::xo::library doc {
  The monaco_storyboard FormField
  Extension of monaco formfield

  @creation-date 2021-11-15
  @author Michael S. Feurstein
}

::xo::library require -package xowfstoryboard storyboard-language/error_handler
::xo::library require -package xowfstoryboard storyboard-language/language_model
::xo::library require -package xowfstoryboard storyboard-language/parser
::xo::library require -package xowfstoryboard storyboard-language/visitor
::xo::library require -package xowfstoryboard storyboard-language/worker
::xo::library require -package xowfstoryboard storyboard-language/expression_builder
::xo::library require -package xowfstoryboard storyboard-language/definition_builder
::xo::library require -package xowfstoryboard storyboard-language/step_definitions

namespace eval ::xowiki::formfield {

  Class create monaco_storyboard -superclass monaco -ad_doc {
    trying to extend on what antonio did
  } -parameter {
	{language "tcl"}
	{theme "vs"}
	{notation natural-language}
	{width 800px}
	{height 450px}
	{autosave:boolean false}
  }

  monaco_storyboard instproc initialize {} {
	next
	if {${:autosave}} {
      ::xo::Page requireJS  "/resources/xowfstoryboard/autosave-monaco.js"
    }

	set wf_notation [${:object} get_property -name wf_notation]
	if {$wf_notation eq ""} {
		ns_log notice "--- monaco_storyboard initialize p.wf_notation empty, using notation:${:notation}"
	} else {
		ns_log notice "--- monaco_storyboard initialize p.wf_notation available, using notation:$wf_notation"
		set :notation $wf_notation
	}
  }

  # TODO: also make sure that it works with
  # - storyboard.form
  # - storyboard.wf
  # - experiment.wf
  monaco_storyboard instproc render_input args {
	ns_log notice "++++ monaco_storyboard private render_input"

	if {${:language} eq "storyboard-language"} {
		security::csp::require script-src 'unsafe-inline'

		template::add_body_script -script {var require = { paths: { 'vs': '/resources/xowf-monaco-plugin/monaco-editor/min/vs' } };}
		template::add_body_script -src urn:ad:js:monaco:min/vs/loader
		template::add_body_script -src urn:ad:js:monaco:min/vs/editor/editor.main.nls
		template::add_body_script -src urn:ad:js:monaco:min/vs/editor/editor.main
	}

	#try {
	#	#set value [:value]
	#	#set parsed_storyboard [:parse_storyboard [:fromBase64 $value]]
	#	#set htmlPreview [dict get $parsed_storyboard html]
	#
	#	#set htmlPreview [ad_text_to_html [${:object} get_property -name htmlPreview]]
	#} on error {errorMsg} {
	#	set htmlPreview ""
	#}

	###
	#
	# Syntax Highlighting
	#
	# Based on the custom-languages example with monarch
	# https://microsoft.github.io/monaco-editor/playground.html#extending-language-services-custom-languages
	#
	# Works both with key-value and natural-language syntax
	#
	# Note that this is a draft working example not fully finished
	# and not used in the actual experiment
	#
	# Open issues:
	# - which colors should be set for what
	# - comments are not colored / supported
	# - possibly missing tokens
	# - code completion only works with what is define in 'registerCompletionItemProvider' - the free monaco code completion of what has already been typed is not integrated with this language definition
	# - numbers should be colored as well in some way
	# - sync with common grounds of syntax highlighting approachs
	#
	###

	if {${:language} eq "storyboard-language"} {
		template::add_body_script -script [subst -nocommands -novariables -nobackslashes {
			// Register a new language
			monaco.languages.register({ id: 'storyboard-language' });

			// Register a tokens provider for storyboard-language
			monaco.languages.setMonarchTokensProvider('storyboard-language', {
				tokenizer: {
				root: [
					[/(Create)( module| textpage| video| timestamp| question)/, ['command','element-type']],
					[/(Create)(.*?)( question)/, ['command','italic','element-type']],
					[/(http:\/\/www\.|https:\/\/www\.|http:\/\/|https:\/\/)?[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(:[0-9]{1,5})?(\/.*)?/, 'http-link'],
					[/\".*?\"/, 'quotes'],
					[/^module|textpage|video|timestamp|question/, 'element-type'],
					[/(module|textpage|video|timestamp|question) /, 'element-type'],
					[/^Create|Set|Add/, 'command'],
					[/\ id | title | body | URL | type | answers | answer | feedback | question | time | timestamps | timestamp | structure /, 'attributes']
				]
				}
			});

			// Define a new theme that contains only rules that match storyboard-language
			monaco.editor.defineTheme('sbl-theme', {
				base: 'vs',
				inherit: false,
				rules: [
					{ token: 'http-link', foreground: 'ff0000', fontStyle: 'italic' },
					{ token: 'quotes', foreground: '808080' },
					{ token: 'command', foreground: '0000CC' },
					{ token: 'italic', foreground: '000000', fontStyle: 'italic'},
					{ token: 'element-type', foreground: '008800' },
					{ token: 'attributes', foreground: 'FFA500' }
				],
				colors: {
					'editor.foreground': '#000000'
				}
			});

			// Register a completion item provider for storyboard-language
			monaco.languages.registerCompletionItemProvider('storyboard-language', {
				provideCompletionItems: () => {
					var suggestions = [
						{
							label: 'module',
							kind: monaco.languages.CompletionItemKind.Text,
							insertText: 'module'
						},
						{
							label: 'textpage',
							kind: monaco.languages.CompletionItemKind.Text,
							insertText: 'textpage'
						},
						{
							label: 'video',
							kind: monaco.languages.CompletionItemKind.Text,
							insertText: 'video'
						},
						{
							label: 'timestamp',
							kind: monaco.languages.CompletionItemKind.Text,
							insertText: 'timestamp'
						},
						{
							label: 'question',
							kind: monaco.languages.CompletionItemKind.Text,
							insertText: 'question'
						}
					];
					return { suggestions: suggestions };
				}
			});
		}]
	}

	# This element is invisible and contains the base64 encoded value
    # of the formfield, which is used for the autosave feature.
    ::html::textarea -id "${:id}-srcdoc" style "display:none;" {
      ::html::t [:value]
    }

      if {${:autosave}} {
        ::html::div -class "autosave" {
          ::html::div -id ${:id}-status \
              -class "nochange" \
              -data-saved #xowiki.autosave_saved# \
              -data-rejected #xowiki.autosave_rejected# \
              -data-pending #xowiki.autosave_pending# {
                ::html::t "" ;#"no change"
              }

			  ::html::div -id ${:id}-container -class storyboardContainer {
				::html::div -id ${:id}-code -class "storyboardEditor"  {
					if {${:language} eq "storyboard-language"} {
						# use own code (supports custom syntax highlighting)
						:create_monaco_editor
					} else {
						# use upstream code (no support for custom syntax highlighting)
						next
					}
				}
			  }

        }

		template::add_event_listener \
            -id ${:id} \
            -event keyup \
            -preventdefault=false \
            -script "autosave_handler('${:id}');"

      } else {
		::html::div -id ${:id}-container -class storyboardContainer {
			::html::div -id ${:id}-code -class "storyboardEditor"  {
				if {${:language} eq "storyboard-language"} {
					# use own code (supports custom syntax highlighting)
					:create_monaco_editor
				} else {
					# use upstream code (no support for custom syntax highlighting)
					next
				}
			}
		}
      }

	#::html::div -id ${:id}-container -class storyboardContainer {
    #  ::html::div -id ${:id}-code -class "storyboardEditor"  {
    #    next
    #  }
        #::html::div -id ${:id}-preview -class "storyboardPreview" {
        #  ::html::t $htmlPreview
        #}
    #}

    #template::add_body_handler -event load -script [subst -nocommands {
    #  var srcDoc = document.getElementById('${:id}-srcdoc');
	#  //console.log("srcDoc: " + srcDoc);
    #  var page = xowf.monaco.b64_to_utf8(srcDoc.innerHTML);
	#  //console.log("page: " + page);

    #  var preview = document.getElementById('${:id}-preview');
    #  if (preview) {
    #    preview.innerHTML = page;
    #  }
    #}]

	# helper script for autosave functionality
	template::add_body_handler -event load -script [subst -nocommands {
      var srcDoc = document.getElementById('${:id}-srcdoc');
      var page = xowf.monaco.b64_to_utf8(srcDoc.innerHTML);


      // If we have an editor
	  // find it and listen to change events
	  // on change update content into
	  // a hidden textarea
      for (var i = 0; i < xowf.monaco.editors.length ; i++)  {
        var e = xowf.monaco.editors[i];
        var hiddenId = e.getDomNode().parentNode.id + ".hidden";
        if (hiddenId === '${:id}.hidden') {
          e.onDidChangeModelContent((event) => {
			srcDoc.innerHTML = xowf.monaco.utf8_to_b64(e.getValue());
          });
        }
      }
	}]

  }

  ###
  #
  # Create Monaco Editor
  #
  # redundant code from what next actually leads to
  # this is done in order to set language and theme accordingly
  #
  # TODO: find a way to better integrated this (include syntax highlighting in upstream code?)
  #
  ###
  monaco_storyboard instproc create_monaco_editor args {
	set isDisabled [:is_disabled]

    if {!$isDisabled} {
      append :style "width: ${:width};" "height: ${:height};"
    } else {
      lappend :CSSclass "disabled"
    }

    ::html::div [:get_attributes id style {CSSclass class}] {}

	set currentValue [:value]

	if {!$isDisabled} {
      template::add_body_script -script [subst -nocommands {

        xowf.monaco.editors.push(monaco.editor.create(document.getElementById('${:id}'), {
          language: '${:language}', minimap: {enabled: ${:minimap}}, readOnly: ${:readOnly}, theme: '${:theme}'
      }));
        xowf.monaco.editors[xowf.monaco.editors.length-1].setValue(xowf.monaco.b64_to_utf8('$currentValue'));

      }]

      if {!${:readOnly}} {
        ::html::input -type hidden -name ${:name} -id ${:id}.hidden
        template::add_body_script -script {
          $(document).ready(function(){
            $("form").submit(function(event) {
              for (var i = 0; i < xowf.monaco.editors.length ; i++)  {
               var e = xowf.monaco.editors[i];
               if (!e.getRawOptions()["readOnly"]) {
                 var hiddenId = e.getDomNode().parentNode.id + ".hidden";
                 var hiddenEl = document.getElementById(hiddenId);
                 if (hiddenEl != null) {
                   //console.log("are we here separate " + e.getValue());
                   hiddenEl.value = xowf.monaco.utf8_to_b64(e.getValue());
                 }
               }
             }
            });
          });
        }
      }
    } else {
      template::add_body_script -script [subst {
        monaco.editor.colorize(xowf.monaco.b64_to_utf8('$currentValue'), '${:language}')
        .then(html => document.getElementById('${:id}').innerHTML = html);
      }]

  }
}

  # TODO: also make sure that it works with
  # - storyboard.form
  # - storyboard.wf
  # - experiment.wf
  monaco_storyboard instproc pretty_value args {
	# :object is handle to the form page
	# check [${:object} set state]
	# [${:object} instance_attributes]

	#
	# Variables
	#

	set storyboard [:fromBase64 [:value]]
	set base64 [:value]

	#if {$storyboard eq ""} {return {}}

	#
	# StoryBoard preparations
	#

	#namespace path ::StoryBoard
	#namespace import ::StoryBoard::*
	# ad_log for full stack logging
	# ns_log for "just a message"
	ad_log notice "--- monaco_storyboard pretty_value sb:$storyboard"

	if {[string is space $storyboard]} {
		return
	}

	#set parsed_storyboard [:parse_storyboard $storyboard]
	#set htmlPreview [dict get $parsed_storyboard html]i
	set htmlPreview [${:object} get_property -name htmlPreview]

	#set modules [dict get $parsed_storyboard modules]

	#set sb_modules [llength $modules]
	#set sb_id [$modules id get]
	#set sb_title [$modules title get]
	#set sb_structure [$modules structure get]

	set sb_modules "n/a"
	set sb_id "n/a"
	set sb_title "n/a"
	set sb_structure "n/a"

	#
	# JS preparations
	#

	template::add_body_script -script {var require = { paths: { 'vs': '/resources/xowf-monaco-plugin/monaco-editor/min/vs' } };}
	template::add_body_script -src urn:ad:js:monaco:min/vs/loader
	template::add_body_script -src urn:ad:js:monaco:min/vs/editor/editor.main.nls
	template::add_body_script -src urn:ad:js:monaco:min/vs/editor/editor.main
	template::add_body_handler -event load -script [subst -nocommands {

		var srcDoc = document.getElementById('${:id}-srcdoc');
		var page = xowf.monaco.b64_to_utf8(srcDoc.innerHTML);
		console.log("page: " + page);

		xowf.monaco.editors.push(monaco.editor.create(document.getElementById('${:id}'), {
		  language: '${:language}', minimap: {enabled: ${:minimap}}, readOnly: true, theme: '${:theme}'
		}));
		xowf.monaco.editors[xowf.monaco.editors.length-1].setValue(xowf.monaco.b64_to_utf8('$base64'));
G
	}]

	#
	# Return HTML preparations
	#

	return [subst -nocommands {

	 <template id="${:id}-srcdoc" style="display:none;">$base64</template>

	 <div class="row">
		<div id="${:id}" class="${:CSSclass} storyboardEditor" style="width: ${:width}; height: ${:height};"></div>
		<div class="storyboardPreview">$htmlPreview</div>
		<div class="storyboardLog">
			Modules: $sb_modules
			<br>
			ID: $sb_id
			<br>
			Title: $sb_title
			<br>
			Structure: $sb_structure
		</div>
	 </div>
	}]
  }

  monaco_storyboard instproc render_item {} {
	ns_log notice "--- monaco_storyboard render_item"
	next
  }

  #
  # Validator for formfield
  #
  # set inside form_constraints
  # editor:monaco_storyboard,validator=storyboard
  #
  monaco_storyboard instproc check=storyboard {value} {
	#ns_log notice "--- monaco_storyboard check=storyboard:$value"
	#:uplevel [list set errorMsg "value is: $value"]
	upvar errorMsg errorMsg
	:uplevel [list set __langPkg xowfstoryboard]
	# TODO: refactor so we use ::xowfstoryboard::check_storyboard here
	return [expr {![catch {:parse_storyboard [:fromBase64 $value]} errorMsg]}]
  }

  # TODO: remove as soon as validator is refactored
  monaco_storyboard instproc parse_storyboard {storyboard} {
	namespace import ::StoryBoard::*

	# destroy all instances of type Element
	# in order to prevent accumulation of zombie modules
	foreach i [StoryBoard::Element info instances -closure] {
		$i destroy
	}

	# ad_log for full stack logging
	# ns_log for "just a message"
	ns_log notice "--- monaco_storyboard parse_storyboard sb:$storyboard"
	ns_log notice "--- monaco_storyboard parse_storyboard notation:${:notation}"

	set internalBuilder [StoryboardBuilder new -notation ${:notation}]

	if {${:notation} eq "key-value"} {
		# kv
		set internalParser [StoryboardParser new -storyboard $storyboard]
		set module [$internalBuilder from [$internalParser storyboardDict get]]
	} elseif {${:notation} eq "natural-language"} {
		# nl
		set dictBuilder [StepDefinitions setup]
		set storyboardDict [$dictBuilder get $storyboard]
		set module [$internalBuilder from $storyboardDict]
	}

	set visitor [HTMLVisitor new]
	set htmlResult [$visitor evaluate $module]
	return [list html [$htmlResult asHTML] modules [Module info instances -closure]]
  }

}
