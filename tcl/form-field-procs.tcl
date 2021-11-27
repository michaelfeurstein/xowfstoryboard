source /var/www/oacs-5-10-0/packages/xowfstoryboard/tcl/storyboard-language/language_model.tcl
source /var/www/oacs-5-10-0/packages/xowfstoryboard/tcl/storyboard-language/parser.tcl
source /var/www/oacs-5-10-0/packages/xowfstoryboard/tcl/storyboard-language/visitor.tcl
source /var/www/oacs-5-10-0/packages/xowfstoryboard/tcl/storyboard-language/worker.tcl
source /var/www/oacs-5-10-0/packages/xowfstoryboard/tcl/storyboard-language/expression_builder.tcl

namespace eval ::xowiki::formfield {

  Class create monaco_storyboard -superclass monaco -ad_doc {
    trying to extend on what antonio did
  } -parameter {
    {storyboardSyntax key-value}
  }

  monaco_storyboard instproc pretty_value args {
	#
	# Variables
	#

	set storyboard [:fromBase64 [:value]]
	set base64 [:value]

	#
	# StoryBoard preparations
	#

	namespace path ::StoryBoard
	ns_log notice "--- monaco_storyboard sb:$storyboard"
	set internalParser [StoryboardParser new -storyboard $storyboard]
	set internalBuilder [StoryBoard::StoryboardBuilder new]
	set module [$internalBuilder from [$internalParser storyboardDict get]]

	set visitor [::StoryBoardVisitor::HTMLVisitor new]
	set htmlResult [$visitor evaluate $module]

	set sb_modules [llength [StoryBoard::Module info instances -closure]]
	set sb_id [[StoryBoard::Module info instances -closure] id get]
	set sb_title [[StoryBoard::Module info instances -closure] title get]
	set sb_structure [[StoryBoard::Module info instances -closure] structure get]

	set htmlPreview [$htmlResult asHTML]
	#set htmlPreview "something"

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

	return [subst -nocommands {

	 <template id="${:id}-srcdoc" style="display:none;">$base64</template>

	 <div class="row">
		<div id="${:id}" class="${:CSSclass} col-md-8" style="width: ${:width}; height: ${:height};"></div>
		<div class="col-md-4">$htmlPreview</div>
	 </div>
	 <div style="width: ${:width}; height: ${:height};" id="${:id}-status">
		Modules: $sb_modules
		<br>
		ID: $sb_id
		<br>
		Title: $sb_title
		<br>
		Structure: $sb_structure
	 </div>



	}]
  }

  monaco_storyboard instproc render_item {} {
	ns_log notice "--- monaco_storyboard render_item"
	next
  }

}
