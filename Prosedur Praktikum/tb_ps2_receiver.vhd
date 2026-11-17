library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_ps2_receiver is
end tb_ps2_receiver;

architecture sim of tb_ps2_receiver is
  signal clk        : std_logic := '0';
  signal ps2_clk    : std_logic := '1';
  signal ps2_data   : std_logic := '1';
  signal scan_code  : std_logic_vector(7 downto 0);
  signal data_ready : std_logic;
  signal rx_count   : integer := 0;

  constant T_SYS : time := 10 ns;   -- 100 MHz
  constant T_PS2 : time := 60 us;   -- ~16,7 kHz

  type code_array is array (0 to 2) of std_logic_vector(7 downto 0);
  constant EXPECT : code_array := (x"1C", x"F0", x"1C");
begin
  uut: entity work.ps2_receiver
    port map (clk => clk, ps2_clk => ps2_clk, ps2_data => ps2_data,
              scan_code => scan_code, data_ready => data_ready);

  clk <= not clk after T_SYS/2;

  stim: process
    procedure send_byte(data : in std_logic_vector(7 downto 0);
                        bad_parity : in boolean := false) is
      variable frame : std_logic_vector(10 downto 0);
      variable p     : std_logic := '1';
    begin
      for i in 0 to 7 loop
        p := p xor data(i);              -- p = bit odd parity
      end loop;
      if bad_parity then p := not p; end if;
      frame(0)          := '0';          -- start
      frame(8 downto 1) := data;         -- data, LSB dulu
      frame(9)          := p;            -- parity
      frame(10)         := '1';          -- stop
      for i in 0 to 10 loop
        ps2_data <= frame(i);
        wait for T_PS2/4;
        ps2_clk <= '0';                  -- tepi turun: data disampel
        wait for T_PS2/2;
        ps2_clk <= '1';
        wait for T_PS2/4;
      end loop;
      ps2_data <= '1';
      wait for 100 us;                   -- jeda antar byte
    end procedure;
  begin
    wait for 100 us;
    send_byte(x"1C");                    -- make  'A'
    send_byte(x"F0");                    -- prefix break
    send_byte(x"1C");                    -- break 'A'
    send_byte(x"1C", true);              -- parity salah -> harus ditolak
    wait for 200 us;
    assert rx_count = 3
      report "GAGAL: jumlah byte diterima = " & integer'image(rx_count) & " (harusnya 3)"
      severity error;
    if rx_count = 3 then
      report "SUKSES: semua pengujian lolos" severity note;
    end if;
    wait;
  end process;

  monitor: process(clk)
  begin
    if rising_edge(clk) then
      if data_ready = '1' then
        assert rx_count <= 2
          report "GAGAL: frame parity salah ikut diterima" severity error;
        if rx_count <= 2 then
          assert scan_code = EXPECT(rx_count)
            report "GAGAL: scan_code tidak sesuai harapan" severity error;
        end if;
        rx_count <= rx_count + 1;
      end if;
    end if;
  end process;
end sim;