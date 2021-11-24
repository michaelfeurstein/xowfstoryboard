source /var/www/oacs-5-10-0/packages/xowfstoryboard/tcl/storyboard-language/language_model.tcl
source /var/www/oacs-5-10-0/packages/xowfstoryboard/tcl/storyboard-language/parser.tcl
source /var/www/oacs-5-10-0/packages/xowfstoryboard/tcl/storyboard-language/worker.tcl
source /var/www/oacs-5-10-0/packages/xowfstoryboard/tcl/storyboard-language/expression_builder.tcl

namespace eval ::xowiki::formfield {

  Class create monaco_storyboard -superclass monaco -ad_doc {
    trying to extend on what antonio did
  } -parameter {
    {storyboardSyntax key-value}
  }

  monaco_storyboard instproc pretty_value args {
	namespace path ::StoryBoard
	StoryBoard::Video new -id video1
    ns_log notice "--- monaco_storyboard videos:[llength [StoryBoard::Video info instances -closure]]"
	ns_log notice "--- monaco_storyboard value:[:value]"
	set storyboard [:fromBase64 [:value]]
	ns_log notice "--- monaco_storyboard sb:$storyboard"
	set internalParser [StoryboardParser new -storyboard $storyboard]
	set internalBuilder [StoryBoard::StoryboardBuilder new]
	set module [$internalBuilder from [$internalParser storyboardDict get]]
	ns_log notice "\nModule: [llength [StoryBoard::Module info instances -closure]]"
	ns_log notice " - id: [[StoryBoard::Module info instances -closure] id get]"
	ns_log notice " - title: [[StoryBoard::Module info instances -closure] title get]"
	ns_log notice " - structure: [[StoryBoard::Module info instances -closure] structure get]"
	set modules [llength [StoryBoard::Module info instances -closure]]

	template::add_body_script -script {var require = { paths: { 'vs': '/resources/xowf-monaco-plugin/monaco-editor/min/vs' } };}
	template::add_body_script -src urn:ad:js:monaco:min/vs/loader
	template::add_body_script -src urn:ad:js:monaco:min/vs/editor/editor.main.nls
	template::add_body_script -src urn:ad:js:monaco:min/vs/editor/editor.main

	set base64 [:value]
	template::add_body_handler -event load -script [subst -nocommands {

	var srcDoc = document.getElementById('${:id}-srcdoc');
	var page = xowf.monaco.b64_to_utf8(srcDoc.innerHTML);
	console.log("page: " + page);

	xowf.monaco.editors.push(monaco.editor.create(document.getElementById('${:id}'), {
          language: '${:language}', minimap: {enabled: ${:minimap}}, readOnly: true, theme: '${:theme}'
      }));
	xowf.monaco.editors[xowf.monaco.editors.length-1].setValue(xowf.monaco.b64_to_utf8('$base64'));


	}]

	# CONTINUE HERE: inside the div class Form-monaco setup a structure for a side by side view of editor and generated preview. Step A: this 2 column structzre and Step B: start visitor to generate preview for the right side
	return [subst -nocommands {

	 <template id="${:id}-srcdoc" style="display:none;">$base64</template>

	 <div>Modules: $modules</div>

	 <div id="${:id}" classe="${:CSSclass}" style="width: ${:width}; height: ${:height};"></div>


	}]
  }

  monaco_storyboard instproc render_item {} {
	ns_log notice "--- monaco_storyboard render_item"
	next
  }

}
