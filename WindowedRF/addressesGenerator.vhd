library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.functions.all;
use work.constants.all;

-- AddressesGenerator converts the virtual addresses into physical, considering the current windows pointer cwp
entity addressesGenerator is

    generic (
        -- Word bits size
        size_word              : integer := 32;
        -- Number of global registers
        m_global               : integer := 10;
        -- Number of registers in each IN/OUT/LOCAL window
        n_in_out_local         : integer := 4;
        -- Number of windows
        f_windows              : integer := 3;
        -- Address size for the external address (virtual address)
        size_ext_addr          : integer := log2(m_global_const + (n_in_out_local_const*3));
        -- Address size for the external address (physical address)
        size_int_addr          : integer := log2(m_global_const + (n_in_out_local_const*2)*f_windows_const + n_in_out_local_const);
        -- Number of windows binary
        size_windows           : integer := log2(f_windows_const)
    );
    port (
        -- Virtual address input
        addr_read_one_in       : in std_logic_vector(size_ext_addr-1 downto 0);
        addr_read_two_in       : in std_logic_vector(size_ext_addr-1 downto 0);
        addr_write_in          : in std_logic_vector(size_ext_addr-1 downto 0);
        cwp_in                 : in std_logic_vector(size_windows-1 downto 0);
        -- Physical address output
        addr_read_one_out      : out std_logic_vector(size_int_addr-1 downto 0);
        addr_read_two_out      : out std_logic_vector(size_int_addr-1 downto 0);
        addr_write_out         : out std_logic_vector(size_int_addr-1 downto 0)
    );
end entity;

architecture behavioral of addressesGenerator is

begin

    -- Process used to compute the addresses
    addr_gen                   : process (addr_read_one_in, addr_read_two_in, addr_write_in, cwp_in)

        -- Variables used into the process
        variable cwp           : integer range 0 to f_windows;
        variable addr_read_one : integer range 0 to size_ext_addr;
        variable addr_read_two : integer range 0 to size_ext_addr;
        variable addr_write    : integer range 0 to size_ext_addr;

        begin
            cwp                := to_integer(unsigned(cwp_in));
            addr_read_one      := to_integer(unsigned(addr_read_one_in));
            addr_read_two      := to_integer(unsigned(addr_read_two_in));
            addr_write         := to_integer(unsigned(addr_write_in));

            -- Translates the virtual address to physical one
            -- Physical address = virtual address + cwp*(2*n_in_out_local)
            -- First of all we should check if the virtual address refers to a global register

            if(addr_read_one < m_global) then
                -- If it is a global register, the physical address will be just the virtual one
                addr_read_one_out <= '0' & addr_read_one_in;
            else
                -- Otherwise we must add the offset to reach the right physical address
                addr_read_one_out <= std_logic_vector(to_unsigned(cwp*(2*n_in_out_local) + addr_read_one, addr_read_one_out'length));
            end if;

            if(addr_read_two < m_global) then
                -- It is a global register
                addr_read_two_out <= '0' & addr_read_two_in;
            else
                -- We must add the offset to reach the physical address
                addr_read_two_out <= std_logic_vector(to_unsigned(cwp*(2*n_in_out_local) + addr_read_two, addr_read_one_out'length));
            end if;

            if(addr_write < m_global) then
                -- It is a global register
                addr_write_out <= '0' & addr_write_in;
            else
                -- We must add the offset to reach the physical address
                addr_write_out <= std_logic_vector(to_unsigned(cwp*(2*n_in_out_local) + addr_write, addr_read_one_out'length));
            end if;
        end process;

end architecture;
