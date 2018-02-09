##############################################################################
## This file is part of 'axi-pcie-core'.
## It is subject to the license terms in the LICENSE.txt file found in the 
## top-level directory of this distribution and at: 
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
## No part of 'axi-pcie-core', including this file, 
## may be copied, modified, propagated, or distributed except according to 
## the terms contained in the LICENSE.txt file.
##############################################################################

set_property RAM_STYLE ULTRA [get_cells -hierarchical -filter {NAME=~*NON_BUILT_IN_GEN.FIFO_SYNC_Gen.FifoSync_Inst/GEN_RAM.SimpleDualPortRam_Inst}]
