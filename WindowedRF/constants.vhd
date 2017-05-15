library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.functions.all;

package constants is

    constant size_word_const      : integer := 32;
    constant m_global_const       : integer := 10;
    constant n_in_out_local_const : integer := 4;
    constant f_windows_const      : integer := 3;
    constant size_ext_addr_const  : integer := log2(m_global_const + (n_in_out_local_const*3));
    constant size_int_addr_const  : integer := log2(m_global_const + (n_in_out_local_const*2)*f_windows_const + n_in_out_local_const);
    constant size_windows_const   : integer := log2(f_windows_const);
end package;
