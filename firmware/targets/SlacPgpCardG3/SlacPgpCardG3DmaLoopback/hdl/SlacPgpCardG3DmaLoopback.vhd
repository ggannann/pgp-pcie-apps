-------------------------------------------------------------------------------
-- File       : SlacPgpCardG3DmaLoopback.vhd
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- This file is part of 'PGP PCIe APP DEV'.
-- It is subject to the license terms in the LICENSE.txt file found in the 
-- top-level directory of this distribution and at: 
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
-- No part of 'PGP PCIe APP DEV', including this file, 
-- may be copied, modified, propagated, or distributed except according to 
-- the terms contained in the LICENSE.txt file.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

use work.StdRtlPkg.all;
use work.AxiPkg.all;
use work.AxiLitePkg.all;
use work.AxiStreamPkg.all;
use work.AxiPciePkg.all;
use work.SsiPkg.all;

library unisim;
use unisim.vcomponents.all;

entity SlacPgpCardG3DmaLoopback is
   generic (
      TPD_G                : time                     := 1 ns;
      ROGUE_SIM_EN_G       : boolean                  := false;
      ROGUE_SIM_PORT_NUM_G : natural range 0 to 65535 := 1;
      DMA_SIZE_G           : positive                 := 1;
      BUILD_INFO_G         : BuildInfoType);
   port (
      -- PGP GT Serial Ports
      pgpRefClkP : in    sl;
      pgpRefClkN : in    sl;
      pgpRxP     : in    slv(7 downto 0);
      pgpRxN     : in    slv(7 downto 0);
      pgpTxP     : out   slv(7 downto 0);
      pgpTxN     : out   slv(7 downto 0);
      -- EVR GT Serial Ports
      evrRefClkP : in    slv(1 downto 0);
      evrRefClkN : in    slv(1 downto 0);
      evrMuxSel  : out   slv(1 downto 0);
      evrRxP     : in    sl;
      evrRxN     : in    sl;
      evrTxP     : out   sl;
      evrTxN     : out   sl;
      -- User LEDs
      ledDbg     : out   sl;
      ledRedL    : out   slv(5 downto 0);
      ledBlueL   : out   slv(5 downto 0);
      ledGreenL  : out   slv(5 downto 0);
      -- FLASH Interface 
      flashAddr  : out   slv(28 downto 0);
      flashData  : inout slv(15 downto 0);
      flashAdv   : out   sl;
      flashCeL   : out   sl;
      flashOeL   : out   sl;
      flashWeL   : out   sl;
      -- PCIe Ports
      pciRstL    : in    sl;
      pciRefClkP : in    sl;            -- 100 MHz
      pciRefClkN : in    sl;            -- 100 MHz
      pciRxP     : in    slv(3 downto 0);
      pciRxN     : in    slv(3 downto 0);
      pciTxP     : out   slv(3 downto 0);
      pciTxN     : out   slv(3 downto 0));
end SlacPgpCardG3DmaLoopback;

architecture top_level of SlacPgpCardG3DmaLoopback is

   signal axilClk : sl;
   signal axilRst : sl;

   signal dmaClk     : sl;
   signal dmaRst     : sl;
   signal dmaMasters : AxiStreamMasterArray(DMA_SIZE_G-1 downto 0);
   signal dmaSlaves  : AxiStreamSlaveArray(DMA_SIZE_G-1 downto 0);

begin

   axilClk <= dmaClk;
   axilRst <= dmaRst;

   U_Core : entity work.AxiPciePgpCardG3Core
      generic map (
         TPD_G                => TPD_G,
         ROGUE_SIM_EN_G       => ROGUE_SIM_EN_G,
         ROGUE_SIM_PORT_NUM_G => ROGUE_SIM_PORT_NUM_G,
         BUILD_INFO_G         => BUILD_INFO_G,
         DMA_SIZE_G           => DMA_SIZE_G)
      port map (
         ------------------------      
         --  Top Level Interfaces
         ------------------------        
         -- DMA Interfaces
         dmaClk         => dmaClk,
         dmaRst         => dmaRst,
         dmaObMasters   => dmaMasters,
         dmaObSlaves    => dmaSlaves,
         dmaIbMasters   => dmaMasters,
         dmaIbSlaves    => dmaSlaves,
         -- AXI-Lite Interface
         appClk         => axilClk,
         appRst         => axilRst,
         appReadMaster  => open,
         appReadSlave   => AXI_LITE_READ_SLAVE_EMPTY_OK_C,
         appWriteMaster => open,
         appWriteSlave  => AXI_LITE_WRITE_SLAVE_EMPTY_OK_C,
         -------------------
         --  Top Level Ports
         -------------------             
         -- Boot Memory Ports 
         flashAddr      => flashAddr,
         flashData      => flashData,
         flashAdv       => flashAdv,
         flashCeL       => flashCeL,
         flashOeL       => flashOeL,
         flashWeL       => flashWeL,
         -- PCIe Ports 
         pciRstL        => pciRstL,
         pciRefClkP     => pciRefClkP,
         pciRefClkN     => pciRefClkN,
         pciRxP         => pciRxP,
         pciRxN         => pciRxN,
         pciTxP         => pciTxP,
         pciTxN         => pciTxN);

   ledDbg    <= '0';
   ledRedL   <= (others => '1');
   ledBlueL  <= (others => '1');
   ledGreenL <= (others => '1');
   evrMuxSel <= (others => '0');

   U_Evr : entity work.Gtpe2ChannelDummy
      generic map (
         TPD_G   => TPD_G,
         WIDTH_G => 1)
      port map (
         refClk   => axilClk,
         gtRxP(0) => evrRxP,
         gtRxN(0) => evrRxN,
         gtTxP(0) => evrTxP,
         gtTxN(0) => evrTxN);

   U_QSFP0 : entity work.Gtpe2ChannelDummy
      generic map (
         TPD_G   => TPD_G,
         WIDTH_G => 4)
      port map (
         refClk => axilClk,
         gtRxP  => pgpRxP(3 downto 0),
         gtRxN  => pgpRxN(3 downto 0),
         gtTxP  => pgpTxP(3 downto 0),
         gtTxN  => pgpTxN(3 downto 0));

   U_QSFP1 : entity work.Gtpe2ChannelDummy
      generic map (
         TPD_G   => TPD_G,
         WIDTH_G => 4)
      port map (
         refClk => axilClk,
         gtRxP  => pgpRxP(7 downto 4),
         gtRxN  => pgpRxN(7 downto 4),
         gtTxP  => pgpTxP(7 downto 4),
         gtTxN  => pgpTxN(7 downto 4));

end top_level;