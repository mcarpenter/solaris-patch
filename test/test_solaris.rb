
require 'test/unit'
require 'solaris'

# Unit tests for top level require.
class TestSolaris < Test::Unit::TestCase #:nodoc:

  def test_solaris
    assert_nothing_raised { Solaris }
  end

  def test_solaris_patch
    assert_nothing_raised { Solaris::Patch }
  end

  def test_solaris_patchdiag
    assert_nothing_raised { Solaris::Patchdiag }
  end

  def test_solaris_patchdiag_entry
    assert_nothing_raised { Solaris::PatchdiagEntry }
  end

  def test_test
    assert_raise( NameError ) { Solaris::DoesNotExist }
  end

end

