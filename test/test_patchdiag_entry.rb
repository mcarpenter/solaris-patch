require 'test/unit'
require 'solaris/patchdiag_entry'

# Unit tests for class PatchdiagEntry.
class TestPatchdiagEntry < Test::Unit::TestCase #:nodoc:

  def test_146636_01
    line = '146336|01|Jan/13/11| | | |  |10|sparc;118833-36;120011-14;127127-11;137137-09;142909-17;|SUNWarc:11.10.0,REV=2005.01.21.15.53;SUNWcsl:11.10.0,REV=2005.01.21.15.53;|SunOS 5.10: libsldap.so.1 patch'
    pde = Solaris::PatchdiagEntry.new(line)
    assert_equal(146336, pde.major)
    assert_equal(1, pde.minor)
    assert_equal(false, pde.recommended?)
    assert_equal(false, pde.obsolete?)
    assert_equal(false, pde.security?)
    assert_equal(Date.new(2011, 1, 13), pde.date)
    assert_equal('10', pde.os)
    assert_equal('146336-01', pde.patch.to_s)
    assert_equal(['SUNWarc:11.10.0,REV=2005.01.21.15.53',
                  'SUNWcsl:11.10.0,REV=2005.01.21.15.53'], pde.pkgs)
    assert_equal(['sparc', '118833-36', '120011-14', '127127-11', '137137-09', '142909-17'], pde.archs)
    assert_equal('SunOS 5.10: libsldap.so.1 patch', pde.synopsis)
    assert_equal(line, pde.to_s)
  end

  def test_100393_01
    line = '100393|01|Sep/02/94| | |O|  |Unbundled|||OBSOLETED by 100394'
    pde = Solaris::PatchdiagEntry.new(line)
    assert_equal(100393, pde.major)
    assert_equal(1, pde.minor)
    assert_equal(false, pde.recommended?)
    assert_equal(true, pde.obsolete?)
    assert_equal(false, pde.security?)
    assert_equal(Date.new(1994, 9, 2), pde.date)
    assert_equal('Unbundled', pde.os)
    assert_equal('100393-01', pde.patch.to_s)
    assert_equal([], pde.pkgs)
    assert_equal([], pde.archs)
    assert_equal('OBSOLETED by 100394', pde.synopsis)
    assert_equal(line, pde.to_s)
  end

  def test_146364_01
    line = '146364|01|Jan/04/11|R|S| |  |10_x86|i386;119758-19;|SUNWsfman:11.10.0,REV=2005.01.08.01.09;SUNWsmbaS:11.10.0,REV=2005.01.08.01.09;SUNWsmbar:11.10.0,REV=2005.01.08.01.09;SUNWsmbau:11.10.0,REV=2005.01.08.01.09;|SunOS 5.10_x86: Samba patch'
    pde = Solaris::PatchdiagEntry.new(line)
    assert_equal(146364, pde.major)
    assert_equal(1, pde.minor)
    assert_equal(true, pde.recommended?)
    assert_equal(false, pde.obsolete?)
    assert_equal(true, pde.security?)
    assert_equal(Date.new(2011, 1, 4), pde.date)
    assert_equal('10_x86', pde.os)
    assert_equal('146364-01', pde.patch.to_s)
    assert_equal(['SUNWsfman:11.10.0,REV=2005.01.08.01.09',
                 'SUNWsmbaS:11.10.0,REV=2005.01.08.01.09',
                 'SUNWsmbar:11.10.0,REV=2005.01.08.01.09',
                 'SUNWsmbau:11.10.0,REV=2005.01.08.01.09'],
                 pde.pkgs)
    assert_equal(['i386', '119758-19'], pde.archs)
    assert_equal('SunOS 5.10_x86: Samba patch', pde.synopsis)
    assert_equal(line, pde.to_s)
  end

  def test_date_padding
    line = '103346|30|Oct/03/02| | | |  |Unbundled|||Hardware/PROM: Sun Enterprise 3x00/4x00/5x00/6x00 flashprom update'
    pde = Solaris::PatchdiagEntry.new(line)
    assert_equal(line, pde.to_s)
  end

  def test_compare_equal
    line = '100393|01|Sep/02/94| | |O|  |Unbundled|||OBSOLETED by 100394'
    assert_equal(Solaris::PatchdiagEntry.new(line),
                 Solaris::PatchdiagEntry.new(line))
  end

  def test_compare_less_than
    line1 = '100393|01|Sep/02/94| | |O|  |Unbundled|||OBSOLETED by 100394'
    line2 = '146364|01|Jan/04/11|R|S| |  |10_x86|i386;119758-19;|SUNWsfman:11.10.0,REV=2005.01.08.01.09;SUNWsmbaS:11.10.0,REV=2005.01.08.01.09;SUNWsmbar:11.10.0,REV=2005.01.08.01.09;SUNWsmbau:11.10.0,REV=2005.01.08.01.09;|SunOS 5.10_x86: Samba patch'
    assert(Solaris::PatchdiagEntry.new(line1) < Solaris::PatchdiagEntry.new(line2))
  end

  def test_successor
    assert_raise(Solaris::Patch::NotObsolete) do
      successor('100287|05|Oct/31/91| | | |  |Unbundled|||PC-NFS 3.5c: Jumbo patch (updated PRT.COM to v3.5c)')
    end
    assert_equal('110258-01', successor('109687|01|Aug/11/00| | |O|  |Unbundled|sparc;|VRTSvxvm:3.0.4,REV=04.18.2000.10.00;|Obsoleted by : 110258-01 VxVM 3.0.4: vxio and vxdmp driver patch'))
    assert_equal('101318-94', successor('101859|01|Feb/06/01| | |O|  |2.3|sparc;|SUNWcsr:11.5.0,REV=2.0.19,PATCH=118;|Obsoleted by: 101318-94 SunOS 5.3: socket lib in 2.3/2.2 have prob'))
    assert_equal('106542', successor('107440|01|Mar/26/99| | |O|  |7_x86||SUNWcar:11.7.0,REV=1998.09.01.04.53;|OBSOLETED by: 106542  SunOS 5.7_x86: /platform/i86pc/kernel/mmu/mm'))
    assert_equal('109212-02', successor('108191|01|Sep/07/99| | |O| B|Unbundled|||Obsoleted by: 109212-02 OBSOLETED by WITHDRAWN'))
    assert_raise(Solaris::Patch::InvalidSuccessor) do
      successor('100807|03|May/02/94| | |O| B|Unbundled|||OBSOLETED by WITHDRAWN')
    end
    assert_equal('100394', successor('100393|01|Sep/02/94| | |O|  |Unbundled|||OBSOLETED by 100394'))
    assert_raise(Solaris::Patch::MultipleSuccessors) do
      successor('105716|07|Jun/30/99| |S|O|  |Unbundled||SUNWdtbas:1.0.2,REV=10.96.04.12;|OBSOLETED by 108363 and 108289')
    end
    assert_raise(Solaris::Patch::MultipleSuccessors) do
      successor('105717|06|Jun/30/99| |S|O|  |Unbundled||SUNWdtbas:1.0.2,REV=10.96.04.12;|OBSOLETED by 108290 and 108364')
    end
    assert_equal('110256-01', successor('109685|02|Feb/09/01| | |O|  |Unbundled|sparc;|VRTSvxvm:3.0.4,REV=04.18.2000.10.00;|Obsoleted by 110256-01: VxVM 3.0.4: vxio and vxdmp driver patch'))
    assert_equal('110257-01', successor('109686|02|Feb/09/01| | |O|  |Unbundled|sparc;|VRTSvxvm:3.0.4,REV=04.18.2000.10.00;|OBSOLETED by 110257-01: VxVM 3.0.4: vxio and vxdmp driver patch'))
    assert_equal('106513-07', successor('106513|06|Oct/03/00| | |O| B|Unbundled|sparc;|SUNWosafw:6.01,REV=01.11;SUNWosau:6.01,REV=01.11;108555-02;|WITHDRAWN Obsoleted by: 106513-07 RM 6.1.1: generic Raid Manager 6'))
    assert_raise(Solaris::Patch::InvalidSuccessor) do
      # NB fudged the obsolete flag here
      successor('111442|01|May/04/01| | |O| B|2.5.1|sparc;sparc.sun4c;sparc.sun4d;sparc.sun4m;sparc.sun4u;sparc.sun4u1;103640-35;|SUNWcar:11.5.1,REV=96.05.02.21.09;SUNWcar:11.5.1,REV=97.02.21.21.14;SUNWcsr:11.5.1,REV=96.05.02.21.09;103640-36;|WITHDRAWN PATCH Obsolete by: <INTEGRATION> SunOS 5.5.1: Supplement')
    end
    assert_equal('103901-08', successor('103901|07|Aug/05/97| |S|O| B|2.5.1|||WITHDRAWN PATCH Obsoleted by: 103901-08 OpenWindows 3.5.1: Xview P'))
    assert_raise(Solaris::Patch::InvalidSuccessor) do
      # NB fudged the obsolete flag here
      successor('111433|02|Jun/04/01| | |O| B|8|sparc;sparc.sun4d;sparc.sun4m;sparc.sun4u;sparc.sun4us;108528-08;|FJSVhea:1.0,REV=1999.12.23.19.10;SUNWcar:11.8.0,REV=2000.01.08.18.12;SUNWcar:11.8.0,REV=2000.01.13.13.40;SUNWcarx:11.8.0,REV=2000.01.08.18.12;SUNWcarx:11.8.0,REV=2000.01.13.13.40;SUNWcsr:11.8.0,REV=2000.01.08.18.12;SUNWhea:11.8.0,REV=2000.01.08.18.12;108528-09;|WITHDRAWN PATCH Obsoleted by: <Integration> SunOS 5.8: Supplementa')
    end
  end

  private

  def successor(line)
    Solaris::PatchdiagEntry.new(line).successor.to_s
  end

end
