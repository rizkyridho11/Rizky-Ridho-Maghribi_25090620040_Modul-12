library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity js12_top is
  Port ( clk     : in  STD_LOGIC;
         PS2Clk  : in  STD_LOGIC;
         PS2Data : in  STD_LOGIC;
         seg     : out STD_LOGIC_VECTOR (6 downto 0);
         dp      : out STD_LOGIC;
         an      : out STD_LOGIC_VECTOR (3 downto 0);
         led     : out STD_LOGIC_VECTOR (15 downto 0) );
end js12_top;

architecture Behavioral of js12_top is
  signal scan_code  : std_logic_vector(7 downto 0);
  signal data_ready : std_logic;
  signal disp_val   : std_logic_vector(15 downto 0) := (others => '0');
begin
  u_ps2: entity work.ps2_receiver
    port map (clk => clk, ps2_clk => PS2Clk, ps2_data => PS2Data,
              scan_code => scan_code, data_ready => data_ready);

  process(clk)
  begin
    if rising_edge(clk) then
      if data_ready = '1' then
        disp_val <= x"00" & scan_code;   -- semua byte (termasuk F0) ditampilkan
      end if;
    end if;
  end process;

  u_sseg: entity work.seven_seg_driver
    port map (clk => clk, value => disp_val, seg => seg, an => an);

  dp  <= '1';
  led(7 downto 0)  <= disp_val(7 downto 0);
  led(15 downto 8) <= (others => '0');
end Behavioral;