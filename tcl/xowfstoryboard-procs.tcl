::xo::db::require package xowiki
::xo::db::require package xowf

namespace eval ::xowfstoryboard {

  ::xo::PackageMgr create ::xowfstoryboard::Package \
      -package_key "xowfstoryboard" \
	  -pretty_name "Storyboard Editor" \
      -superclass ::xowf::Package

  ::xowfstoryboard::Package instproc initialize {} {
        ns_log notice "++++ CALL ::xowfstoryboard::initialize"
        next
  }

}
