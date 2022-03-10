<!-- Generated by ::xowiki::ADP_Generator on Tue Aug 25 20:22:20 CEST 2020 -->
<if @::xowfstoryboard::am_i_admin@ true>

	<master>
                  <property name="context">@context;literal@</property>
                  <if @item_id@ not nil><property name="displayed_object_id">@item_id;literal@</property></if>
                  <property name="&body">body</property>
                  <property name="&doc">doc</property>
                  <property name="head"></property>
	<!-- The following DIV is needed for overlib to function! -->
          <div id="overDiv" style="position:absolute; visibility:hidden; z-index:1000;"></div>
          <div class='xowiki-content'>

      <%
      if {$::xowiki::search_mounted_p} {
        template::add_event_listener  -id wiki-menu-do-search-control  -script {
            document.getElementById('do_search').style.display = 'inline';
            document.getElementById('do_search_q').focus();
          }
      }
      %>
      <div id='wikicmds'>
      <if @view_link@ not nil><a href="@view_link@" accesskey='v' title='#xowiki.view_title#'>#xowiki.view#</a> &middot; </if>
      <if @edit_link@ not nil><a href="@edit_link@" accesskey='e' title='#xowiki.edit_title#'>#xowiki.edit#</a> &middot; </if>
      <if @rev_link@ not nil><a href="@rev_link@" accesskey='r' title='#xowiki.revisions_title#'>#xotcl-core.revisions#</a> &middot; </if>
      <if @new_link@ not nil><a href="@new_link@" accesskey='n' title='#xowiki.new_title#'>#xowiki.new_page#</a> &middot; </if>
      <if @delete_link@ not nil><a href="@delete_link@" accesskey='d' title='#xowiki.delete_title#'>#xowiki.delete#</a> &middot; </if>
      <if @admin_link@ not nil><a href="@admin_link@" accesskey='a' title='#xowiki.admin_title#'>#xowiki.admin#</a> &middot; </if>
      <if @notification_subscribe_link@ not nil><a href='/notifications/manage' title='#xowiki.notifications_title#'>#xowiki.notifications#</a>
      <a href="@notification_subscribe_link@" class="notification-image-button">&nbsp;</a>&middot; </if>
      <if @::xowiki::search_mounted_p@ true><a href='#' id='wiki-menu-do-search-control' title='#xowiki.search_title#'>#xowiki.search#</a> &middot; </if>
      <if @index_link@ not nil><a href="@index_link@" accesskey='i' title='#xowiki.index_title#'>#xowiki.index#</a></if>
      <div id='do_search' style='display: none'>
      <form action='/search/search'><div><label for='do_search_q'>#xowiki.search#</label><input id='do_search_q' name='q' type='text'><input type="hidden" name="search_package_id" value="@package_id@"><if @::__csrf_token@ defined><input type="hidden" name="__csrf_token" value="@::__csrf_token;literal@"></if></div></form>
      </div>
      </div>

</if>
<else>
	<master src="/www/blank-master">
    <property name="context">@context;literal@</property>
    <if @item_id@ not nil><property name="displayed_object_id">@item_id;literal@</property></if>
    <property name="&body">body</property>
    <property name="&doc">doc</property>
    <property name="head"></property>
	<!-- The following DIV is needed for overlib to function! -->
    <div id="overDiv" style="position:absolute; visibility:hidden; z-index:1000;"></div>
    <div class='xowiki-content'>
</else>

<!--  @top_includelets;noquote@ -->


<if @body.menubarHTML@ not nil><div class='visual-clear'><!-- --></div>@body.menubarHTML;noquote@</if>
<if @page_context@ not nil><h4>@body.title@ (@page_context@)</h4></if>
<else><div class="top-title"><div class="experiment-title"><h4 class="page-title">@body.title@</h4></div></div></else>

<div class="xowfstoryboard-content">
@content;noquote@
</div>

@footer;noquote@
</div>
<!-- class='xowiki-content' -->
