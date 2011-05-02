
module Solaris

  class Patch

    # Superclass for all throwable exceptions.
    class Exception < ::Exception ; end

    # Exception is raised by #find_successor when the patch whose
    # successor is to be sought or the supposed successor to a patch
    # does not exist in patchdiag.xref.
    class NotFound < Exception ; end

    # Exception is raised when the terminal (non-obsolete) succesor
    # to a patch has been withdrawn (is bad).
    class BadSuccessor < Exception ; end

    # Raised if the "obsoleted by" value for this patchdiag entry is not
    # comprehensible.
    class InvalidSuccessor < Exception ; end

    # Raised if a patchdiag entry appears to have multiple successors.
    class MultipleSuccessors < Exception ; end

    # Raised if one tries to determine the successor of a non-obsolete patch.
    class NotObsolete < Exception ; end

  end

end # Solaris

