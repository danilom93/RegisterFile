library ieee;
use ieee.std_logic_1164.all;
use work.functions.all;
use work.constants.all;

entity windowedRegisterFile is

    generic (
        -- Word bits size
        size_word           : integer := 32;
        -- Number of global registers
        m_global            : integer := 10;
        -- Number of registers in each IN/OUT/LOCAL window
        n_in_out_local      : integer := 4;
        -- Number of windows
        f_windows           : integer := 3;
        -- Address size for the external address
        size_ext_addr       : integer := log2(m_global_const + (n_in_out_local_const*3))
    );

    port (
        -- Input ports
        data_in_write       : in std_logic_vector(size_word-1 downto 0);
        addr_write          : in std_logic_vector(size_ext_addr-1 downto 0);
        addr_read_one       : in std_logic_vector(size_ext_addr-1 downto 0);
        addr_read_two       : in std_logic_vector(size_ext_addr-1 downto 0);

        -- Out ports
        data_out_port_one   : out std_logic_vector(size_word-1 downto 0);
        data_out_port_two   : out std_logic_vector(size_word-1 downto 0);
        fill                : out std_logic;
        spill               : out std_logic;
        -- Control signals (Active high)
        -- Signal used to call a subroutine
        call                : in std_logic;
        -- Signal used to return from a subroutine
        ret                 : in std_logic;
        -- Signal used by the MMU to tell when a spill/fill operation is completed
        mmu_done            : in std_logic;

        -- Synchronous signals
        clock               : in std_logic;
        reset               : in std_logic;
        enable              : in std_logic;
        read_en_one         : in std_logic;
        read_en_two         : in std_logic;
        write_en            : in std_logic
    );
end entity;

architecture structural of windowedRegisterFile is

    component addressesGenerator
        generic (
          size_word         : integer := 32;
          m_global          : integer := 10;
          n_in_out_local    : integer := 4;
          f_windows         : integer := 3;
          size_ext_addr     : integer := log2(m_global_const + (n_in_out_local_const*3));
          size_int_addr     : integer := log2(m_global_const + (n_in_out_local_const*2)*f_windows_const + n_in_out_local_const);
          size_windows      : integer := log2(f_windows_const)
        );
        port (
          addr_read_one_in  : in std_logic_vector(size_ext_addr-1 downto 0);
          addr_read_two_in  : in std_logic_vector(size_ext_addr-1 downto 0);
          addr_write_in     : in std_logic_vector(size_ext_addr-1 downto 0);
          cwp_in            : in std_logic_vector(size_windows-1 downto 0);
          addr_read_one_out : out std_logic_vector(size_int_addr-1 downto 0);
          addr_read_two_out : out std_logic_vector(size_int_addr-1 downto 0);
          addr_write_out    : out std_logic_vector(size_int_addr-1 downto 0)
        );
    end component addressesGenerator;

    component controUnit
        generic (
          f_windows         : integer := 3;
          size_windows      : integer := size_windows_const
        );
        port (
          clock             : in std_logic;
          reset             : in std_logic;
          enable            : in std_logic;
          call              : in std_logic;
          ret               : in std_logic;
          mmu_done          : in std_logic;
          fill              : out std_logic;
          spill             : out std_logic;
          cwp_out           : out std_logic_vector(size_windows-1 downto 0)
        );
    end component controUnit;


    component register_file
        generic (
          nBitsData         : integer := 64;
          nBitsAddr         : integer := 5
        );
        port (
          CLK               : IN std_logic;
          RESET             : IN std_logic;
          ENABLE            : IN std_logic;
          RD1               : IN std_logic;
          RD2               : IN std_logic;
          WR                : IN std_logic;
          ADD_WR            : IN std_logic_vector(nBitsAddr-1 downto 0);
          ADD_RD1           : IN std_logic_vector(nBitsAddr-1 downto 0);
          ADD_RD2           : IN std_logic_vector(nBitsAddr-1 downto 0);
          DATAIN            : IN std_logic_vector(nBitsData-1 downto 0);
          OUT1              : OUT std_logic_vector(nBitsData-1 downto 0);
          OUT2              : OUT std_logic_vector(nBitsData-1 downto 0)
        );
    end component register_file;

    constant size_windows   : integer := log2(f_windows);
    constant size_int_addr  : integer := log2(m_global + (n_in_out_local*2)*f_windows + n_in_out_local);

    signal cwp_s            : std_logic_vector (size_windows-1 downto 0);
    signal addr_read_one_s  : std_logic_vector (size_int_addr-1 downto 0);
    signal addr_read_two_s  : std_logic_vector (size_int_addr-1 downto 0);
    signal addr_write_s     : std_logic_vector (size_int_addr-1 downto 0);
begin

    m_AD                    : addressesGenerator
        generic map (
          size_word => size_word_const,
          m_global => m_global_const,
          n_in_out_local => n_in_out_local_const,
          f_windows => f_windows_const,
          size_ext_addr => size_ext_addr_const,
          size_int_addr => size_int_addr_const,
          size_windows => size_windows_const
        )
        port map (
          addr_read_one_in => addr_read_one,
          addr_read_two_in => addr_read_two,
          addr_write_in => addr_write,
          cwp_in => cwp_s,
          addr_read_one_out => addr_read_one_s,
          addr_read_two_out => addr_read_two_s,
          addr_write_out => addr_write_s
        );

    m_CU                    : controUnit
        generic map (
          f_windows => f_windows_const,
          size_windows => size_windows_const
        )
        port map (
          clock => clock,
          reset => reset,
          enable => enable,
          call => call,
          ret => ret,
          mmu_done => mmu_done,
          fill => fill,
          spill => spill,
          cwp_out => cwp_s
        );

    m_RF                    : register_file
        generic map (
          nBitsData => size_word_const,
          nBitsAddr => size_int_addr_const
        )
        port map (
          CLK => clock,
          RESET => reset,
          ENABLE => enable,
          RD1 => read_en_one,
          RD2 => read_en_two,
          WR => write_en,
          ADD_WR => addr_write_s,
          ADD_RD1 => addr_read_one_s,
          ADD_RD2 => addr_read_two_s,
          DATAIN => data_in_write,
          OUT1 => data_out_port_one,
          OUT2 => data_out_port_two
        );

end architecture;
