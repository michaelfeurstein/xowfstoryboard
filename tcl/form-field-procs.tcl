::xo::library doc {
  The monaco_storyboard FormField
  Extension of monaco formfield

  @creation-date 2021-11-15
  @author Michael S. Feurstein
}

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
    {notation:required empty}
  }

  monaco_storyboard instproc initialize {} {
	next
	#::xo::Page requireCSS "/resources/xowf-monaco-plugin/plugin.css"
    ::xo::Page requireCSS urn:ad:css:xowfstoryboard:storyboard
  }

  monaco_storyboard instproc render_input args {
	ns_log notice "++++ monaco_html_sandbox private render_input"

	try {
		set value [:value]
		set parsed_storyboard [:parse_storyboard [:fromBase64 $value]]
		set htmlPreview [dict get $parsed_storyboard html]
	} on error {errorMsg} {
		set htmlPreview ""
	}

	# This element is invisible and contains the base64 encoded value
    # of the formfield, which we use to initialize the previews. One
    # could also do it using the editor api, but we do not have one in
    # case of a readonly field or when we render this field in display
    # mode.
	ns_log notice "++++ monaco_html_sandbox private render_input value:[:value]"
    ::html::template -id "${:id}-srcdoc" style "display:none;" {
      ::html::t [ns_base64encode -- $htmlPreview]
    }

	::html::div -id ${:id}-container -class storyboardContainer {
      ::html::div -id ${:id}-code -class "storyboardEditor"  {
        next
      }
        ::html::div -id ${:id}-preview -class "storyboardPreview" {
          ::html::t $htmlPreview
        }
    }

    template::add_body_handler -event load -script [subst -nocommands {
      var srcDoc = document.getElementById('${:id}-srcdoc');
	  //console.log("srcDoc: " + srcDoc);
      var page = xowf.monaco.b64_to_utf8(srcDoc.innerHTML);
	  //console.log("page: " + page);

      var preview = document.getElementById('${:id}-preview');
      if (preview) {
        preview.innerHTML = page;
      }
    }]
  }

  monaco_storyboard instproc pretty_value args {
	# check [${:object} set state]
	# depending on state
	# do different stuff inside
	# :object is handle to the form page

	#
	# Variables
	#

	set storyboard [:fromBase64 [:value]]
	set base64 [:value]

	#
	# StoryBoard preparations
	#

	#namespace path ::StoryBoard
	namespace import ::StoryBoard::*
	# ad_log for full stack logging
	# ns_log for "just a message"
	ad_log notice "--- monaco_storyboard pretty_value sb:$storyboard"

	set parsed_storyboard [:parse_storyboard $storyboard]
	set htmlPreview [dict get $parsed_storyboard html]

	set modules [dict get $parsed_storyboard modules]

	set sb_modules [llength $modules]
	set sb_id [$modules id get]
	set sb_title [$modules title get]
	set sb_structure [$modules structure get]

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

	}]

	#
	# Return HTML preparations
	#

	set test [::xowfstoryboard::hello]

	return [subst -nocommands {

	 <template id="${:id}-srcdoc" style="display:none;">$base64</template>

	 <div class="row">
		<div id="${:id}" class="${:CSSclass} storyboardEditor" style="width: ${:width}; height: ${:height};"></div>
		<div class="storyboardPreview">$htmlPreview</div>
		<div class="storyboardLog">
			Modules: $sb_modules $test
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

  monaco_storyboard instproc check=storyboard {value} {
	ns_log notice "--- monaco_storyboard check=storyboard:$value"
	# build up logic here
	# whatever the parser returns
	# show here
	#:uplevel [list set errorMsg "This is BS! $value"]
	upvar errorMsg errorMsg
	:uplevel [list set __langPkg xowfstoryboard]
	return [expr {![catch {::StoryBoard::StoryboardParser new -storyboard [:fromBase64 $value]} errorMsg]}]
  }

  monaco_storyboard instproc parse_storyboard {storyboard} {
	namespace import ::StoryBoard::*

	# destroy all instances of type Element
	# in order to prevent accumulation of zombie modules
	foreach i [StoryBoard::Element info instances -closure] {
		$i destroy
	}

	# ad_log for full stack logging
	# ns_log for "just a message"
	ad_log notice "--- monaco_storyboard parse_storyboard sb:$storyboard"
	ad_log notice "--- monaco_storyboard parse_storyboard notation:${:notation}"
	#ns_log notice "--- object set state: [${:object} set state] 1:[[[${:object} wf_context] wf_container] set wf_notation] 2:[[${:object} wf_context] get_property wf_notation]"
	ns_log notice "--- wf_notation try 01: [[${:object} wf_context] get_property -name wf_notation]"
	ns_log notice "--- instance_attributes try 01: [${:object} instance_attributes]"
	ns_log notice "--- instance_attributes try 02: [${:object} get_property -name wf_notation]"
	ns_log notice "--- wf_notation try 02: [[[${:object} wf_context] wf_container] set wf_notation]"


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
