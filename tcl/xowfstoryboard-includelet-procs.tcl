namespace eval ::xowiki::includelet {

    ::xowiki::IncludeletClass create xowfstoryboard_includelet \
        -superclass ::xowiki::Includelet \
        -parameter {
            {__decoration none}
			{
                parameter_declaration {
                    {-experiment_id:optional 0}
                }
            }
        }

    xowfstoryboard_includelet ad_instproc render_summary_page {} {
		This includelet renders the summary page

		@return HTML
	} {

		#
		# Get all properties of workflow
		#
		set name [${:__including_page} get_property -name _name]
		set time_elapsed [${:__including_page} get_property -name time_elapsed]
		set editor_b64 [${:__including_page} get_property -name editor]
		set editor [::xowfstoryboard::fromBase64 $editor_b64]
		set htmlPreview [${:__including_page} get_property -name htmlPreview]

		#
		# Prepare template body for separate monaco editor
		#
		template::add_body_script -script {var require = { paths: { 'vs': '/resources/xowf-monaco-plugin/monaco-editor/min/vs' } };}
        template::add_body_script -src urn:ad:js:monaco:min/vs/loader
        template::add_body_script -src urn:ad:js:monaco:min/vs/editor/editor.main.nls
        template::add_body_script -src urn:ad:js:monaco:min/vs/editor/editor.main
		template::add_body_script -src urn:ad:js:monaco:plugin
		template::head::add_css -href urn:ad:css:xowfstoryboard:storyboard

		template::add_body_handler -event load -script [subst -nocommands {

                var srcDoc = document.getElementById('editor-summary-srcdoc');
                var page = xowf.monaco.b64_to_utf8(srcDoc.innerHTML);
                console.log("page: " + page);

                xowf.monaco.editors.push(monaco.editor.create(document.getElementById('editor-summary'), {
                  language: 'tcl', minimap: {enabled: true}, readOnly: true, theme: 'vs'
                }));
                xowf.monaco.editors[xowf.monaco.editors.length-1].setValue(xowf.monaco.b64_to_utf8('$editor_b64'));

		}]

		#
		# Return HTML
		#
		return [subst {
			<div class="top-summary">
				<p><b>Experiment ID: $name</b></p>
				<p>Time elapsed: $time_elapsed</p>
			</div>

			<template id="editor-summary-srcdoc" style="display:none;">$editor_b64</template>

			<div class="main-wrapper">
                <div class="sb-editor">
					<div class="form-group">
						<div class="form-label">
							<label class="editor">Storyboard (read-only)</label>
						</div>
						<div class="">
							<div id="editor-summary" class="xowf-monaco-container storyboardEditor" style="width: 800px; height: 600px;"></div>
						</div>
					</div>
				</div>
                <div class="sb-preview">
					<div class="form-label">
							<label class="editor">Result</label>
						</div>
						$htmlPreview
				</div>
			</div>
        }]
	}

	xowfstoryboard_includelet ad_instproc render_thank_you_page {} {
		This includelet renders the thank you page

		@return HTML
	} {
		set name [string range [${:__including_page} get_property -name _name] 3 end]

		return [subst {
			<center>
				<p>Please stop your timer or note down the current time.</p>
				<p>Please copy your elapsed time and the following experiment ID to your limesurvey</p>
				<p><span style="font-size: 2em; font-weight: bold;">ID: $name</span></p>
				<p>and continue with the questionnaire.</p>
				<p>Thank you!</p>
			</center>
        }]
	}


	xowfstoryboard_includelet ad_instproc render {} {

        Renders the xowfstoryboard includelet.

		The includelet is rendered based on your permissions.
		Public users will only see a Thank you! page.
		Admins (SWAs) will see a summary page of the experiment treatment.

        @return HTML
    } {
		if {[::xowfstoryboard::am_i_admin]} {
			set html [:render_summary_page]
		} else {
			set html [:render_thank_you_page]
		}

        return $html
    }
}
