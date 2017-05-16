library ieee;
use ieee.std_logic_1164.all;
use work.constants.all;
use work.functions.all;

entity testbench is

end entity;

architecture test of testbench is

    signal data_in_write     : std_logic_vector(size_word_const-1 downto 0);
    signal addr_write        : std_logic_vector(size_ext_addr_const-1 downto 0);
    signal addr_read_one     : std_logic_vector(size_ext_addr_const-1 downto 0);
    signal addr_read_two     : std_logic_vector(size_ext_addr_const-1 downto 0);
    signal data_out_port_one : std_logic_vector(size_word_const-1 downto 0);
    signal data_out_port_two : std_logic_vector(size_word_const-1 downto 0);
    signal fill              : std_logic;
    signal spill             : std_logic;
    signal call              : std_logic;
    signal ret               : std_logic;
    signal mmu_done          : std_logic;
    signal clock             : std_logic;
    signal reset             : std_logic;
    signal enable            : std_logic;
    signal read_en_one       : std_logic;
    signal read_en_two       : std_logic;
    signal write_en          : std_logic;

    component windowedRegisterFile
    generic (
      size_word              : integer := 32;
      m_global               : integer := 10;
      n_in_out_local         : integer := 4;
      f_windows              : integer := 3;
      size_ext_addr          : integer := log2(m_global_const + (n_in_out_local_const*3))
    );
    port (
      data_in_write          : in std_logic_vector(size_word-1 downto 0);
      addr_write             : in std_logic_vector(size_ext_addr-1 downto 0);
      addr_read_one          : in std_logic_vector(size_ext_addr-1 downto 0);
      addr_read_two          : in std_logic_vector(size_ext_addr-1 downto 0);
      data_out_port_one      : out std_logic_vector(size_word-1 downto 0);
      data_out_port_two      : out std_logic_vector(size_word-1 downto 0);
      fill                   : out std_logic;
      spill                  : out std_logic;
      call                   : in std_logic;
      ret                    : in std_logic;
      mmu_done               : in std_logic;
      clock                  : in std_logic;
      reset                  : in std_logic;
      enable                 : in std_logic;
      read_en_one            : in std_logic;
      read_en_two            : in std_logic;
      write_en               : in std_logic
    );
    end component windowedRegisterFile;

begin

    uut                      : windowedRegisterFile
        generic map (
          size_word => size_word_const,
          m_global => m_global_const,
          n_in_out_local => n_in_out_local_const,
          f_windows => f_windows_const,
          size_ext_addr => size_ext_addr_const
        )
        port map (
          data_in_write => data_in_write,
          addr_write => addr_write,
          addr_read_one => addr_read_one,
          addr_read_two => addr_read_two,
          data_out_port_one => data_out_port_one,
          data_out_port_two => data_out_port_two,
          fill => fill,
          spill => spill,
          call => call,
          ret => ret,
          mmu_done => mmu_done,
          clock => clock,
          reset => reset,
          enable => enable,
          read_en_one => read_en_one,
          read_en_two => read_en_two,
          write_en => write_en
        );

        clkProc              : process
        begin

				clock <= '0';
				wait for 1 ns;
				clock <= '1';
				wait for 1 ns;
        end process;

        stimProc             : process
        begin

            data_in_write 	<= x"00000000";
            -- Using the configuration with:
            -- m_global_const = 5
            -- n_in_out_local_const = 2
			addr_read_one 	<= "0100";    -- register 4 which is a global register, has not to change depending on the cwp value
			addr_read_two 	<= "0101";    -- register 5 which is the first in register, changes depending on cwp
			addr_write		<= "0111";    -- register 7 which is the first local register, changes depending on cwp
            call 	        <= '0';
            ret 	        <= '0';
            mmu_done 	    <= '1';       -- Here it is supposed that the MMU complete the spill, fill operation just in one clock
                                          -- clock cycle because the mmu_done signal is always high
            read_en_one 	<= '1';
            read_en_two 	<= '1';
            write_en 	    <= '1';
            reset 	        <= '1';      -- Reset operation
            enable 	        <= '1';

                wait for 5 ns;

                reset 	                <= '0';      -- Reset completed

				--									step 1
			    call 	                <= '0';
                
				--									step 2
				wait for 6 ns;
				call 					<= '1';
				wait for 3 ns;
				call 					<= '0';
				--									step 3
				wait for 6 ns;
				call 					<= '1';
				wait for 3 ns;
				call 					<= '0';
				--									step 4
				wait for 6 ns;
				call 					<= '1';
				wait for 3 ns;
				call 					<= '0';
				--									step 5
				wait for 6 ns;
				call 					<= '1';
				wait for 3 ns;
				call 					<= '0';
				--									step 6
				wait for 6 ns;
				ret 					<= '1';
				wait for 3 ns;
				ret 					<= '0';
				--									step 7
				wait for 6 ns;
				ret 					<= '1';
				wait for 3 ns;
				ret 					<= '0';
				--									step 8
				wait for 6 ns;
				ret 					<= '1';
				wait for 3 ns;
				ret 					<= '0';

				wait;


        end process;
end architecture;
