library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.functions.all;

package constants is

    -- number of bits for the word
    constant size_word_const      : integer := 32;
    -- number of global regiters
    constant m_global_const       : integer := 5;
    -- number of regiters in each of the IN or OUT or LOCAL window
    constant n_in_out_local_const : integer := 2;
    -- number of windows
    constant f_windows_const      : integer := 6;
    -- number of bits for the virtual addresses
    constant size_ext_addr_const  : integer := log2(m_global_const + (n_in_out_local_const*3));
    -- number of bits for the physical addresses
    constant size_int_addr_const  : integer := log2(m_global_const + (n_in_out_local_const*2)*f_windows_const + n_in_out_local_const);
    -- number of bits used to represent the number of windows
    constant size_windows_const   : integer := log2(f_windows_const);
end package;
