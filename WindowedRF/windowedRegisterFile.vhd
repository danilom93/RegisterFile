library ieee;
use ieee.std_logic_1164.all;
use work.functions.all;

entity windowedRegisterFile is

    generic (
        -- Word bits size
        size_word         : integer := 32;
        -- Number of global registers
        m_global          : integer := 10;
        -- Number of registers in each IN/OUT/LOCAL window
        n_in_out_local    : integer := 4;
        -- Number of windows
        f_windows         : integer := 3;
        -- Address size for the external address
        size_ext_addr     : integer := log2(m_global + (n_in_out_local*3))
    );

    port (
        -- Input ports
        data_in_write     : in std_logic_vector(size_word-1 downto 0);
        addr_write        : in std_logic_vector(size_ext_addr-1 downto 0);
        addr_read_one     : in std_logic_vector(size_ext_addr-1 downto 0);
        addr_read_two     : in std_logic_vector(size_ext_addr-1 downto 0);

        -- Out ports
        data_out_port_one : out std_logic_vector(size_word-1 downto 0);
        data_out_port_two : out std_logic_vector(size_word-1 downto 0);

        -- Control signals (Active high)
        -- Signal used to call a subroutine
        call              : in std_logic;
        -- Signal used to return from a subroutine
        ret               : in std_logic;
        -- Signal used by the MMU to tell when a spill/fill operation is completed
        mmu_done          : in std_logic;

        -- Synchronous signals
        clock             : in std_logic;
        reset             : in std_logic;
        enable            : in std_logic;
        read_en_one       : in std_logic;
        read_en_two       : in std_logic;
        write_en          : in std_logic
    );
end entity;
