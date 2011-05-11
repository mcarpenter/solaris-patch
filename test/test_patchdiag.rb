
require 'test/unit'
require 'stringio'
require 'solaris/patchdiag'

# Unit tests for class Patchdiag.
class TestPatchdiag < Test::Unit::TestCase #:nodoc:

  def setup
    @empty_file = '/dev/null'
    @patchdiag_string = <<-EOF
## PATCHDIAG TOOL CROSS-REFERENCE FILE AS OF Feb/10/11 ##
##
## The content of this file has changed as of Jun/04/10. Due to the merging of
## the Sun Alert and Recommended patch clusters, some patches tagged with the
## "R" flag may now be obsoleted patches (and as a result additionally have the
## "O" flag set).
## Details of this change are explained in the following blog posting:
## http://blogs.sun.com/patch/entry/merging_the_solaris_recommended_and
## The following Technical Info Document explains the various fields in the
## patchdiag.xref file:
## https://support.oracle.com/CSP/main/article?cmd=show&type=NOT&doctype=REFERENCE&id=1019527.1
100287|05|Oct/31/91| | | |  |Unbundled|||PC-NFS 3.5c: Jumbo patch (updated PRT.COM to v3.5c)
100323|05|Feb/11/92| | | |  |Unbundled|||PC-NFS Advanced Telnet: bug fixes, National Character Set support
100386|01|Sep/20/91| | | |  |Unbundled|||PC-NFS Programmer's Toolkit/2.0: Runtime modules
100393|01|Sep/02/94| | |O|  |Unbundled|||OBSOLETED by 100394
100438|01|Dec/02/91| | | |  |Unbundled|||PCNFS/v3.5c: PC-NFS loses mounted printer names when PCNFSLPD load
100455|01|Dec/17/91| | | |  |Unbundled|||LifeLine/2.0: Does not parse the FROM: and/or Reply-TO: fields cor
100648|01|Jun/11/92| | | |  |Unbundled|||PC-NFS/4.0a: Jumbo Patch
100701|03|Feb/17/93| | | |  |Unbundled|sparc;|SUNWowbcp:1.8.1;SUNWowbcp:2.10;|OpenWindows 3.0.1;3.1: programs compiled under Solaris 1.x /usr/5b
100791|04|Apr/12/93| | |O|  |Unbundled||SPROsw:2.1.0.1;|OBSOLETED by 100974
100791|05|Apr/12/93| | |O|  |Unbundled||SPROsw:2.1.0.1;|OBSOLETED by 100974
100807|03|May/02/94| | |O| B|Unbundled|||OBSOLETED by WITHDRAWN
100807|04|Jul/07/94| | | |  |Unbundled|sparc;|SPROswmgr:2.1.2.1;|Sparcworks 2.0.1: statically linking X11 library doesn't run on As
100811|01|Mar/17/93| | |O|  |Unbundled||SPROcpl:2.1.0.3;SPROlang:2.1.0.3;|OBSOLETED by 100967
100812|02|Jan/27/93| | | |  |Unbundled|sparc;|SUNWowrqd:1.16.2;|OpenWindows 3.0.1: Binder as root with "-system" or "-network" doe
100824|03|Jun/29/93| | | |  |Unbundled|sparc;|SUNWowrqd:2.10;|OpenWindows 3.1: fixes various bugs in xnews server
100830|01|Mar/12/93| | |O|  |Unbundled||SPROlang:2.1.0.1;|OBSOLETED by 100861
100837|01|Jan/20/93| | | |  |Unbundled|sparc;|SUNWowrqd:2.10.0.1;|OpenWindows 3.1: core dump in ras3,ras4,ras5 and install_check on
100843|01|Feb/05/93| | | |  |Unbundled|||PC-NFS/4.0a: various, system or print server hangs under heavy loa
100849|01|Jan/20/93| | |O|  |Unbundled||SPROpas:2.1.0.1;|OBSOLETED by 100964
100852|02|Jul/01/93| | |O|  |2.1||SUNWcsu:11.4.2,PATCH=28;|OBSOLETED by WITHDRAWN
146124|01|Dec/08/10| | | |  |10|sparc;|SUNWthunderbirdl10n-de-DE:3.0.3,REV=101.0.3;SUNWthunderbirdl10n-es-ES:3.0.3,REV=101.0.3;SUNWthunderbirdl10n-extra:3.0.3,REV=101.0.3;SUNWthunderbirdl10n-fr-FR:3.0.3,REV=101.0.3;SUNWthunderbirdl10n-it-IT:3.0.3,REV=101.0.3;SUNWthunderbirdl10n-ja-JP:3.0.3,REV=101.0.3;SUNWthunderbirdl10n-ko-KR:3.0.3,REV=101.0.3;SUNWthunderbirdl10n-pl-PL:3.0.3,REV=101.0.3;SUNWthunderbirdl10n-pt-BR:3.0.3,REV=101.0.3;SUNWthunderbirdl10n-ru-RU:3.0.3,REV=101.0.3;SUNWthunderbirdl10n-sv-SE:3.0.3,REV=101.0.3;SUNWthunderbirdl10n-zh-CN:3.0.3,REV=101.0.3;SUNWthunderbirdl10n-zh-TW:3.0.3,REV=101.0.3;|SunOS 5.10: Thunderbird l10n packages update Patch
146132|01|Jan/05/11| | | |  |10|sparc;137137-09;141444-09;|SUNWcsu:11.10.0,REV=2005.01.21.15.53;|SunOS 5.10: newfs fails on newly-formatted floppy disk
146133|01|Jan/05/11| | | |  |10_x86|i386;137138-09;141445-09;|SUNWcsu:11.10.0,REV=2005.01.21.16.34;|SunOS 5.10_x86: newfs fails on newly-formatted floppy disk
146236|01|Dec/10/10| | | |  |10|sparc;137137-09;|SUNWckr:11.10.0,REV=2005.01.21.15.53;|SunOS 5.10: dcfs patch
146237|01|Dec/10/10| | | |  |10_x86|i386;141445-09;|SUNWckr:11.10.0,REV=2005.01.21.16.34;|SunOS 5.10_x86: dcfs patch
146241|02|Dec/16/10| | | |  |Unbundled|sparc;|SUNWscsaa:3.3.0,REV=2010.07.26.12.56;|Oracle Solaris Cluster 3.3: SWIFTAllianceAccess patch
146277|01|Dec/10/10| | | |  |10|sparc;118833-36;120011-14;127127-11;139555-08;142909-17;|SUNWcslr:11.10.0,REV=2005.01.21.15.53;|SunOS 5.10: libnsl patch
146278|01|Dec/10/10| | | |  |10_x86|i386;118855-36;120012-14;127128-11;139556-08;142910-17;|SUNWcslr:11.10.0,REV=2005.01.21.16.34;|SunOS 5.10_x86: libnsl patch
146279|01|Dec/22/10|R|S| |  |10|sparc;|SUNWbnuu:11.10.0,REV=2005.01.21.15.53;|SunOS 5.10: uucp patch
146280|01|Dec/22/10|R|S| |  |10_x86|i386;|SUNWbnuu:11.10.0,REV=2005.01.21.16.34;|SunOS 5.10_x86: uucp patch
146281|01|Dec/15/10| | | |  |10|sparc;|SUNWckr:11.10.0,REV=2005.01.21.15.53;SUNWhea:11.10.0,REV=2005.01.21.15.53;|SunOS 5.10: ldterm patch
146282|01|Dec/15/10| | | |  |10_x86|i386;|SUNWckr:11.10.0,REV=2005.01.21.16.34;SUNWhea:11.10.0,REV=2005.01.21.16.34;|SunOS 5.10_x86: ldterm patch
146283|01|Dec/10/10| | | |  |10|sparc;118833-36;137137-09;142909-17;|SUNWckr:11.10.0,REV=2005.01.21.15.53;|SunOS 5.10: lofi patch
146284|01|Dec/10/10| | | |  |10_x86|i386;118855-36;137138-09;142910-17;|SUNWckr:11.10.0,REV=2005.01.21.16.34;|SunOS 5.10_x86: lofi patch
146287|01|Jan/24/11| | | |  |10|sparc.sun4u;sparc.sun4us;sparc.sun4v;118833-36;120011-14;|SUNWkvm:11.10.0,REV=2005.01.20.17.25;SUNWkvm:11.10.0,REV=2005.01.21.15.53;SUNWkvm:11.10.0,REV=2005.08.04.12.25;|SunOS 5.10: trapstat Patch
146332|02|Feb/03/11| | | |  |10|sparc;142909-17;|SUNWaccu:11.10.0,REV=2005.01.21.15.53;|SunOS 5.10: sadc patch
146333|02|Feb/03/11| | | |  |10_x86|i386;142910-17;|SUNWaccu:11.10.0,REV=2005.01.21.16.34;|SunOS 5.10_x86: sadc patch
146334|01|Jan/19/11| | | |  |10|sparc;120011-14;121133-02;127127-11;139555-08;142909-17;|SUNWzoneu:11.10.0,REV=2005.01.21.15.53;|SunOS 5.10: zlogin patch
146335|01|Jan/19/11| | | |  |10_x86|i386;120012-14;121334-04;127128-11;139556-08;142910-17;|SUNWzoneu:11.10.0,REV=2005.01.21.16.34;|SunOS 5.10_x86: zlogin patch
146336|01|Jan/13/11| | | |  |10|sparc;118833-36;120011-14;127127-11;137137-09;142909-17;|SUNWarc:11.10.0,REV=2005.01.21.15.53;SUNWcsl:11.10.0,REV=2005.01.21.15.53;|SunOS 5.10: libsldap.so.1 patch
146337|01|Jan/13/11| | | |  |10_x86|i386;120012-14;127128-11;137138-09;142910-17;|SUNWarc:11.10.0,REV=2005.01.21.16.34;SUNWcsl:11.10.0,REV=2005.01.21.16.34;|SunOS 5.10_x86: libsldap.so.1 patch
146363|01|Jan/04/11|R|S| |  |10|sparc;119757-19;|SUNWsfman:11.10.0,REV=2005.01.08.05.16;SUNWsmbaS:11.10.0,REV=2005.01.08.05.16;SUNWsmbar:11.10.0,REV=2005.01.08.05.16;SUNWsmbau:11.10.0,REV=2005.01.08.05.16;|SunOS 5.10: Samba patch
146364|01|Jan/04/11|R|S| |  |10_x86|i386;119758-19;|SUNWsfman:11.10.0,REV=2005.01.08.01.09;SUNWsmbaS:11.10.0,REV=2005.01.08.01.09;SUNWsmbar:11.10.0,REV=2005.01.08.01.09;SUNWsmbau:11.10.0,REV=2005.01.08.01.09;|SunOS 5.10_x86: Samba patch
146435|01|Feb/01/11| | | |  |Unbundled|||Hardware FC  Disk Drive Patch : Download program and FC Disk Drive
146440|01|Jan/13/11| | | |  |10|sparc;118833-36;120011-14;137137-09;139555-08;141444-09;142909-17;|SUNWckr:11.10.0,REV=2005.01.21.15.53;|SunOS 5.10: dld patch
146441|01|Jan/13/11| | | |  |10_x86|i386;118855-36;120012-14;139556-08;141445-09;142910-17;|SUNWckr:11.10.0,REV=2005.01.21.16.34;|SunOS 5.10_x86: dld patch
146442|01|Jan/24/11| | | |  |10|sparc;126897-02;127127-11;127755-01;137137-09;139555-08;141444-09;142909-17;|SUNWfmd:11.10.0,REV=2005.01.21.15.53;|SunOS 5.10: libldom.so.1 patch
146443|01|Feb/09/11| | | |  |10|sparc;142909-17;|SUNWfmd:11.10.0,REV=2005.01.21.15.53;|SunOS 5.10: gmem.eft and generic-mem.so patch
146444|01|Jan/27/11| | | |  |10_x86|i386;120012-14;142910-17;|SUNWnge:11.10.0,REV=2005.06.22.03.40;|SunOS 5.10_x86: nge patch
800054|01|Mar/16/01| | |O|  |Unbundled|||Obsoleted by: 111346-01 Hardware/PROM: Sun Fire 3800/4800/4810/680
100974|02|Mar/14/95| | | |  |Unbundled|sparc;|SPROsw:2.1.0;|SparcWorks 2.0.1: dbx jumbo patch
654321|01|Jan/01/00| | |O|  |Unbundled|||Obsoleted by: 654321-02
654321|02|Jan/01/00| | |O|  |Unbundled|||Obsoleted by: 654321-03
654321|03|Jan/01/00| | |O|  |Unbundled|||Obsoleted by: 654321-01
654322|01|Jan/01/00| | |O|  |Unbundled|||Obsoleted by: 654321-05
115302|01|Jul/08/03| | |O| B|Unbundled|||WITHDRAWN PATCH Obsoleted by: 115302-02 Hardware/PROM: CP2060/CP20
EOF
    @patchdiag_fileish = StringIO.new( @patchdiag_string )
    @patchdiag_size = 56
    @patchdiag = Solaris::Patchdiag.open( @patchdiag_fileish )
  end

  def teardown
    @empty_file = nil
    @patchdiag = nil
    @patchdiag_fileish = nil
    @patchdiag_string = nil
    @patchdiag_size = nil
  end

  def test_new_by_fileish
    assert_equal( @patchdiag_size, @patchdiag.entries.size )
  end

  def test_new_by_filename
    temp = Tempfile.new( 'test_patchdiag' )
    path = temp.path
    temp.write( @patchdiag_fileish )
    temp.close
    patchdiag = Solaris::Patchdiag.new( path )
    File.unlink( path )
    assert_equal( @patchdiag_size, @patchdiag.entries.size )
  end

  def test_new_empty_file
    if File.exists?( @empty_file )
      patchdiag = Solaris::Patchdiag.new( @empty_file )   
      assert_equal( 0, patchdiag.entries.size )
    end
  end

  def test_all
    assert_equal( @patchdiag_size, @patchdiag.all.size )
  end

  def test_all_sort_by_date_order_ascending
    all = @patchdiag.all( :sort_by => :date, :order => :ascending )
    first = all.first.patch # oldest
    last = all.last.patch # newest
    assert_equal( Solaris::Patch.new( '100386-01' ), first )
    assert_equal( Solaris::Patch.new( '146443-01' ), last )
  end

  def test_all_sort_by_patch_order_descending
    all = @patchdiag.all( :sort_by => :patch, :order => :descending )
    first = all.first.patch # largest
    last = all.last.patch # smallest
    assert_equal( Solaris::Patch.new( '800054-01' ), first )
    assert_equal( Solaris::Patch.new( '100287-05' ), last )
  end

  def test_open_block
    ret = Solaris::Patchdiag.open( @patchdiag_fileish ) do |patchdiag|
      assert_equal( Solaris::Patchdiag, patchdiag.class )
      :return_code
    end
    assert_equal( :return_code, ret )
  end

  def test_open_return
    assert_equal( Solaris::Patchdiag, @patchdiag.class )
  end

  def test_find
    assert_equal( [], @patchdiag.find( 123456 ) )
    assert_equal( [], @patchdiag.find( '123456' ) )
    assert_equal( [], @patchdiag.find( '123456-78' ) )
    assert_equal( [], @patchdiag.find( Solaris::Patch.new( 123456 ) ) )
    assert_equal( [], @patchdiag.find( Solaris::Patch.new( '123456' ) ) )
    assert_equal( [], @patchdiag.find( Solaris::Patch.new( '123456-78' ) ) )
    assert_equal( [], @patchdiag.find( '100791-01' ) )
    assert_equal( [], @patchdiag.find( Solaris::Patch.new( '100791-01' ) ) )
    assert_equal( '100791-04', @patchdiag.find( 100791 ).first.patch.to_s )
    assert_equal( '100791-04', @patchdiag.find( '100791' ).first.patch.to_s )
    assert_equal( '100791-04', @patchdiag.find( '100791-04' ).first.patch.to_s )
    assert_equal( '100791-04', @patchdiag.find( Solaris::Patch.new( 100791) ).first.patch.to_s )
    assert_equal( '100791-04', @patchdiag.find( Solaris::Patch.new( '100791') ).first.patch.to_s )
    assert_equal( '100791-04', @patchdiag.find( Solaris::Patch.new( '100791-04') ).first.patch.to_s )
  end

  def test_latest
    assert_raise( Solaris::Patch::NotFound ) do
      @patchdiag.latest( 123456 )
    end
    assert_equal( '100791-05', @patchdiag.latest( 100791 ).patch.to_s )
    assert_equal( '100791-05', @patchdiag.latest( '100791' ).patch.to_s )
    assert_equal( '100791-05', @patchdiag.latest( '100791-01' ).patch.to_s )
    assert_equal( '100791-05', @patchdiag.latest( '100791-05' ).patch.to_s )
    assert_equal( '100791-05', @patchdiag.latest( Solaris::Patch.new( 100791 ) ).patch.to_s )
    assert_equal( '100791-05', @patchdiag.latest( Solaris::Patch.new( '100791' ) ).patch.to_s )
    assert_equal( '100791-05', @patchdiag.latest( Solaris::Patch.new( '100791-01' ) ).patch.to_s )
    assert_equal( '100791-05', @patchdiag.latest( Solaris::Patch.new( '100791-05' ) ).patch.to_s )
  end

  def test_successor
    assert_raise( Solaris::Patch::NotFound ) do
      @patchdiag.latest( 123456 )
    end
    assert_equal( '100287-05', @patchdiag.successor( 100287 ).patch.to_s )
    assert_equal( '100287-05', @patchdiag.successor( '100287' ).patch.to_s )
    assert_equal( '100287-05', @patchdiag.successor( '100287-05' ).patch.to_s )
    assert_equal( '100287-05', @patchdiag.successor( Solaris::Patch.new( '100287-05' ) ).patch.to_s )
    assert_equal( '100974-02', @patchdiag.successor( 100791 ).patch.to_s )
    assert_raise( Solaris::Patch::NotFound ) do
      @patchdiag.successor( 123456 )
    end
    assert_raise( Solaris::Patch::NotFound ) do
      @patchdiag.successor( 100393 ) # successor 100394 not in patchdiag.xref
    end
    assert_raise( Solaris::Patch::NotFound ) do
      @patchdiag.successor( '654322-05' )
    end
    assert_equal( '100807-04', @patchdiag.successor( '100807-01' ).patch.to_s )
    assert_raise( Solaris::Patch::InvalidSuccessor ) do
      @patchdiag.successor( '100807-03' ) # successor 100807-03 WITHDRAWN
    end
    assert_raise( Solaris::Patch::SuccessorLoop ) do
      @patchdiag.successor( 654321 )
    end
    assert_raise( Solaris::Patch::SuccessorLoop ) do
      @patchdiag.successor( '654321-01' )
    end
    assert_raise( Solaris::Patch::NotFound ) do
      @patchdiag.successor( 115302 )
    end
  end

  def test_download!
    skip 'Mock required'
  end

  private

  def successor(patch)
    @patchdiag.successor( patch ).patch.to_s
  end

end

