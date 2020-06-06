--
-- Copyright (C) 2009-2012 Chris McClelland
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU Lesser General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU Lesser General Public License for more details.
--
-- You should have received a copy of the GNU Lesser General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
--
library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


architecture rtl of swled is

	-- initial signals from default cksum
	signal flags 					: std_logic_vector(3 downto 0);
	signal checksum, checksum_next 	: std_logic_vector(15 downto 0) := (others => '0');


	-- signal declarations
	signal encrypted_position, decrypted_ack, encrypted_ack, encrypted_message : std_logic_vector(31 downto 0) := (others => '0');
	signal decrypted_message, plaintext, ciphertext, key					   : std_logic_vector(31 downto 0) := (others => '0');
	signal memory, encrypted_memory 										   : std_logic_vector(63 downto 0);
	


	signal iter,seconds,startprocess,outcnt,wait_time,lights,microstate1 				  : integer := 0;
	signal everythingok, enc_done, dec_done, enc_reset, dec_reset, dec_enable, enc_enable : std_logic := '0';
	


	signal microstate0 			   : integer := -5;
	signal Ack1, position		   : std_logic_vector(31 downto 0);
	signal TrackExists, TrackOK	   : std_logic := '0';
	signal Direction, NextSignal   : std_logic_vector(2 downto 0) := (others => '0');
	signal chanread, chanwrite 	   : std_logic_vector(6 downto 0);
	


	signal uart_rx_data		: std_logic_vector(7 downto 0);
	signal uart_rx_enable	: std_logic;
	signal uart_tx_data		: std_logic_vector(7 downto 0);
	signal uart_tx_enable	: std_logic;
	signal uart_tx_ready	: std_logic;



	signal data_on_uart, data_on_fpga	: std_logic_vector(7 downto 0);
	signal is_data_uart					: std_logic := '0';
	signal count, microstate2, waiter	: integer := 0;
	signal next_cycle,previous_cycle	: std_logic := '0';
	
	

	-- component declarations
	component encrypter is
		Port (	clock : in STD_LOGIC;
				K : in STD_LOGIC_VECTOR(31 downto 0);
				P : in STD_LOGIC_VECTOR(31 downto 0);
				C : out STD_LOGIC_VECTOR(31 downto 0);
				done : out STD_LOGIC;
				reset : in STD_LOGIC;
				enable : in STD_LOGIC);
	end component;
	
	component decrypter is
		Port (	clock : in STD_LOGIC;
				K : in STD_LOGIC_VECTOR(31 downto 0);
				C : in STD_LOGIC_VECTOR(31 downto 0);
				P : out STD_LOGIC_VECTOR(31 downto 0);
				done : out STD_LOGIC;
				reset : in STD_LOGIC;
				enable : in STD_LOGIC);
	end component;

	component basic_uart is
		generic (
		  DIVISOR: natural
		);
		port (	clk: in std_logic;   -- system clock
				reset: in std_logic;
				
				-- Client interface
				rx_data: out std_logic_vector(7 downto 0);  -- received byte
				rx_enable: out std_logic;  -- validates received byte (1 system clock spike)
				tx_data: in std_logic_vector(7 downto 0);  -- byte to send
				tx_enable: in std_logic;  -- validates byte to send if tx_ready is '1'
				tx_ready: out std_logic;  -- if '1', we can send a new byte, otherwise we won't take it
				
				-- Physical interface
				rx: in std_logic;
				tx: out std_logic);
	end component;


begin
	
	basic_uart_inst: basic_uart
	generic map (DIVISOR => 1250) -- 2400
	port map (
		clk => clk_in, reset => reset_in,
		rx_data => uart_rx_data, rx_enable => uart_rx_enable,
		tx_data => uart_tx_data, tx_enable => uart_tx_enable, tx_ready => uart_tx_ready,
		rx => uart_rx,
		tx => uart_tx
	);



	process(clk_in, reset_in)
	begin
		
		if(reset_in = '1') then
			
			checksum 		<= (others => '0');
			microstate0 	<= -4;
			enc_reset 		<= '1';
			next_cycle 		<= '0';
			previous_cycle 	<= '0';
				
		elsif ( rising_edge(clk_in) ) then

			iter <= iter + 1;
				
			if(uart_rx_enable = '1' and is_data_uart = '0') then
				data_on_uart 	<= uart_rx_data;
				is_data_uart 	<= '1';
				next_cycle	 	<= '1';
			end if;

			if(iter = 48000000) then
				
				iter 	<= 0;
				seconds <= seconds + 1;

				if(waiter > 0) then
					waiter <= waiter + 1;
				end if;

				if(microstate0 < -1 and microstate0 > -5) then
					microstate0 <= microstate0 + 1;
					led_out 	<= "11111111";
				end if;

				if (startprocess > 0 and lights = 0) then
					startprocess <= startprocess + 1;
				end if;

				if(startprocess > 0 and lights > 0 and lights < 4) then
					lights <= lights + 1;
				end if;

				if (wait_time > 0) then
					wait_time <= wait_time + 1;
				end if;

			end if;

			if(microstate0 = -1) then


				led_out   <= "00000000";
				chanread  <= "0000011";
				chanwrite <= "0000010";


				Ack1 			<= "11011011101101111101111101101110";
				position 		<= "00000000111111111111111100100010"; 
				key 			<= "11001100110011001100110011000001";


				is_data_uart 	<= '0';
				next_cycle 	 	<= '0';

				
				encrypted_position <= (others => '0');
				encrypted_ack 	   <= (others => '0');
				plaintext 		   <= (others => '0');

				outcnt 		<= 0;
				microstate2	<= 0;
				microstate1 <= 0;
				waiter 		<= 0;

				microstate0 	<= microstate0 + 1;
				
			end if;

			-- Encrypting the position
			if(microstate0 = 0) then
				plaintext 	<= position;
				microstate0 <= microstate0 + 1;
			end if;

			if(microstate0 = 1) then
				enc_reset <= '0';
				enc_enable <= '1';
				microstate0 <= microstate0 + 1;
			end if;

			if(microstate0 = 2 and enc_done = '1') then
				encrypted_position <= ciphertext;
				microstate0 <= microstate0 + 1;
				enc_reset <= '1';
			end if;

			-- Sending the encrypted position to host
			if(microstate0 = 3 and outcnt < 4 and f2hReady_in = '1' and chanAddr_in = chanwrite) then
				outcnt <= outcnt + 1;
			end if;

			-- Waiting for 256 seconds for the message from host
			if(outcnt = 4 and (microstate0 = 3 or microstate0 = 12 or microstate0 = 36)) then
				wait_time <= 1;
			end if;

			-- If Waited for 256 seconds going back to encrypting position
			if(wait_time > 256) then
				microstate0 <= -1;
				outcnt 		<= 0;
				wait_time 	<= 0;
			end if;

			-- Receiving the encrypted position from host
			if (chanAddr_in = chanread and h2fValid_in = '1' and microstate0 > 2 and microstate0 < 7) then
				encrypted_message(8*(microstate0-2) - 1 downto 8*(microstate0-3)) <= h2fData_in;
				microstate0  <= microstate0 + 1;
			end if;

			-- Decrypting the encrypted position from host
			if (microstate0 = 7) then
				dec_reset 	<= '0';
				dec_enable 	<= '1';
				microstate0 <= microstate0 + 1;
				outcnt 		<= 0;
			end if;

			-- Checking if the position from the host is equal to the actual position
			-- If not equal waits for 256 seconds period and goes back to encrypting position
			if(microstate0 = 8 and dec_done = '1') then
				if(decrypted_message(7 downto 0) = position(7 downto 0)) then
					microstate0 <= microstate0 + 1;
					dec_reset 	<= '1';

				elsif(wait_time <= 256 and wait_time > 0) then
					microstate0 <= 3;

				elsif(wait_time > 256) then
					microstate0 <= 0;
					wait_time 	<= 0;
				end if;

			end if;


			-- Encrypting Ack
			if (microstate0 = 9) then
				plaintext 	<= Ack1;
				microstate0 <= microstate0 + 1;
			end if;

			if(microstate0 = 10) then
				enc_reset 	<= '0';
				enc_enable 	<= '1';
				microstate0 <= microstate0 + 1;
			end if;

			if(microstate0 = 11 and enc_done = '1') then
				encrypted_ack 	<= ciphertext;
				microstate0 	<= microstate0 + 1;
				enc_reset 		<= '1';
			end if;
			
			-- Sending enrcypted Ack to host 
			if(microstate0 = 12 and outcnt < 4 and f2hReady_in = '1' and chanAddr_in = chanwrite) then
				outcnt <= outcnt + 1;
			end if;

			-- If it did not receive data from host within 256 seconds after sending the ack goes back to encrypting position
			if (chanAddr_in = chanread and h2fValid_in = '1' and microstate0 > 11 and microstate0 < 16) then
				encrypted_message(8*(microstate0-11) - 1 downto 8*(microstate0-12)) <= h2fData_in;
				microstate0 <= microstate0 + 1;
			end if;

			if (microstate0 = 16) then
				dec_reset 	<= '0';
				dec_enable 	<= '1';
				outcnt 		<= 0;
				microstate0 <= microstate0 + 1;
			end if;

			-- Checking if the ack from the host is equal to the actual ack
			-- If not equal waits for 256 seconds period and goes back to encrypting position
			if(microstate0 = 17 and dec_done = '1') then
				if(decrypted_message = "11110000111100001111000011110000") then
					microstate0 <= microstate0 + 1;
					dec_reset 	<= '1';

				elsif(wait_time <= 256 and wait_time > 0) then
					microstate0 <= 3;

				elsif(wait_time > 256) then
					microstate0 <= 0;
					wait_time 	<= 0;
				end if;

			end if;

			-- Receiving the first 4 encrypted bytes of track data from host
			if (chanAddr_in = chanread and h2fValid_in = '1' and microstate0 > 17 and microstate0 < 22) then
				encrypted_message(8*(microstate0-17) - 1 downto 8*(microstate0-18)) <= h2fData_in;
				microstate0 <= microstate0 + 1;
			end if;

			-- Decrypting the received data from the host
			if (microstate0 = 22) then
				dec_reset 	<= '0';
				dec_enable 	<= '1';
				microstate0 <= microstate0 + 1;
			end if;

			if(microstate0 = 23 and dec_done = '1') then
				memory(31 downto 0) <= decrypted_message;
				microstate0 		<= microstate0 + 1;
				dec_reset 			<= '1';
			end if;


			-- Encrypting Ack
			if (microstate0 = 24) then
				plaintext 	<= Ack1;
				microstate0 <= microstate0 + 1;
			end if;

			if(microstate0 = 25) then
				enc_reset 	<= '0';
				enc_enable 	<= '1';
				microstate0 <= microstate0 + 1;
			end if;

			if(microstate0 = 26 and enc_done = '1') then
				encrypted_ack 	<= ciphertext;
				microstate0 	<= microstate0 + 1;
				enc_reset 		<= '1';
			end if;

			-- Sending encrypted Ack to host
			if(microstate0 = 27 and outcnt < 4 and f2hReady_in = '1' and chanAddr_in = chanwrite) then
				outcnt <= outcnt + 1;
			end if;


			-- Receiving the next 4 bytes of encrypted data from the host
			if (chanAddr_in = chanread and h2fValid_in = '1' and microstate0 > 26 and microstate0 < 31) then
				encrypted_message(8*(microstate0-26) - 1 downto 8*(microstate0-27)) <= h2fData_in;
				microstate0 <= microstate0 + 1;
			end if;

			-- Decrypting the data from host
			if (microstate0 = 31) then
				dec_reset 	<= '0';
				dec_enable 	<= '1';
				outcnt 		<= 0;
				microstate0 <= microstate0 + 1;
			end if;

			if(microstate0 = 32 and dec_done = '1') then
				memory(63 downto 32) 	<= decrypted_message;
				microstate0 			<= microstate0 + 1;
				dec_reset 				<= '1';
			end if;


			-- Encrypting Ack
			if (microstate0 = 33) then
				plaintext <= Ack1;
				microstate0 <= microstate0 + 1;
			end if;

			if(microstate0 = 34) then
				enc_reset 	<= '0';
				enc_enable 	<= '1';
				microstate0 <= microstate0 + 1;
			end if;

			if(microstate0 = 35 and enc_done = '1') then
				encrypted_ack 	<= ciphertext;
				microstate0 	<= microstate0 + 1;
				enc_reset 		<= '1';
			end if;

			-- Sending the encrypted ack
			if(microstate0 = 36 and outcnt < 4 and f2hReady_in = '1' and chanAddr_in = chanwrite) then
				outcnt <= outcnt + 1;
			end if;


			-- Receiving encrypted ack from host
			if (chanAddr_in = chanread and h2fValid_in = '1' and microstate0 > 35 and microstate0 < 40) then
				encrypted_message(8*(microstate0-35) - 1 downto 8*(microstate0-36)) <= h2fData_in;
				microstate0 <= microstate0 + 1;
			end if;

			if (microstate0 = 40) then
				dec_reset 	<= '0';
				dec_enable 	<= '1';
				outcnt 		<= 0;
				microstate0 <= microstate0 + 1;
			end if;

			-- Checking if the ack from the host is equal to the actual ack
			-- If not equal waits for 256 seconds period and goes back to encrypting position
			if(microstate0 = 41 and dec_done = '1') then
				if(decrypted_message = "11110000111100001111000011110000") then
					microstate0 	<= microstate0 + 1;
					dec_reset 		<= '1';
					everythingok 	<= '1'; 

				elsif(wait_time <= 256 and wait_time > 0) then
					microstate0 <= 3;

				elsif(wait_time > 256) then
					microstate0 <= 0;
					wait_time <= 0;
				end if;

			end if;


			-- Checks if the up button is pressed in state 2
			if(everythingok = '1' and microstate1 = 0) then
				if(up = '1') then
					microstate1 <= 1;
				end if; 
			end if;

			-- Checks if the down button is pressed
			if(microstate1 = 1 and down = '1') then
				plaintext(7 downto 0) 	<= sw_in;
				microstate1 			<= 2;
				enc_enable 				<= '1';
				enc_reset 				<= '0';
			end if;

			-- Encrypting the data
			if(microstate1 = 2 and enc_done = '1') then
				data_on_fpga 	<= ciphertext(7 downto 0);
				enc_reset 		<= '1';
				microstate1 	<= 3;
			end if;

			-- Checks if the host read the data
			if(microstate1 = 3 and f2hReady_in = '1') then
				microstate1 <= 4;
				waiter 		<= 1;
			end if;

			-- Checks if the left button is pressed in State 2
			if(everythingok = '1' and microstate2 = 0) then
				if(left = '1') then
					microstate2 <= 1;
				end if; 
			end if;

			-- Ckecks if right button is pressed
			if(microstate2 = 1 and right = '1') then
				uart_tx_enable 	<= '1';
				uart_tx_data 	<= sw_in;
				microstate2 	<= 2;
			end if;

			-- Enabling the uart transmission
			if(microstate2 = 2) then
				uart_tx_enable 	<= '0';
				microstate2 	<= 3;
				waiter 			<= 1;
			end if;

			-- Waits for 15 seconds in the end
			if(waiter = 16) then
				microstate0 <= -1;
				previous_cycle 	<= next_cycle;
			end if;

			-- State 2 begins displays the signal data
			if(everythingok = '1' and startprocess = 0) then
				startprocess <= 1;
			end if;

			-- State 2 ends
			if(startprocess = 9) then
				everythingok 	<= '0';
				startprocess 	<= 0;
				dec_reset 		<= '1';
				led_out 		<= "00000000";

				if(microstate2 = 0 and microstate1 = 0) then
					waiter <= 1;
				end if;

			end if;

			-- Displays the signal info according to the slider switches
			if(startprocess > 0 and startprocess < 9) then
				TrackExists <= memory(8*(startprocess)-1);

				if(previous_cycle = '1') then
					if(data_on_uart(6) = '1') then
						TrackOK <= memory(8*(startprocess)-2);
					else
						TrackOK <= '0';
					end if;
				else
					TrackOK <= memory(8*(startprocess)-2);
				end if;
                
				Direction 			<= memory(8*(startprocess)-3 downto 8*(startprocess)-5);
				NextSignal 			<= memory(8*(startprocess)-6 downto 8*(startprocess)-8);
				led_out(4 downto 3) <= "00";
				led_out(7 downto 5) <= Direction;

				if(TrackExists = '1' and TrackOK = '1' and sw_in(startprocess-1)='1') then
					if((startprocess <= 4 and sw_in(startprocess+3)='1') or (startprocess > 4 and sw_in(startprocess-5)='1')) then
						if(startprocess > 4) then

							if(lights=0) then
								lights <= lights + 1;
							end if;
							if(lights=1) then
								led_out(2 downto 0) <= "100";
							end if;
							if(lights=2) then
								led_out(2 downto 0) <= "010";
							end if;
							if(lights=3) then
								led_out(2 downto 0) <= "001";
							end if;
							if(lights=4) then
								lights 			<= 0;
								startprocess 	<= startprocess + 1;
							end if;

						else

							if(lights=0) then
								lights <= lights + 1;
							end if;
							if(lights=1) then
								led_out(2 downto 0) <= "001";
							end if;
							if(lights=2) then
								led_out(2 downto 0) <= "001";
							end if;
							if(lights=3) then
								led_out(2 downto 0) <= "001";
							end if;
							if(lights=4) then
								lights 			<= 0;
								startprocess 	<= startprocess + 1;
							end if;

						end if;
                    else

                        if(NextSignal = "001") then
                            if(lights=0) then
                                lights <= lights + 1;
                            end if;
                            if(lights=1) then
                                led_out(2 downto 0) <= "010";
                            end if;
                            if(lights=2) then
                                led_out(2 downto 0) <= "010";
                            end if;
                            if(lights=3) then
                                led_out(2 downto 0) <= "010";
                            end if;
                            if(lights=4) then
                                lights 			<= 0;
                                startprocess 	<= startprocess + 1;
                            end if;

                        else

                            if(lights=0) then
                                lights <= lights + 1;
                            end if;
                            if(lights=1) then
                                led_out(2 downto 0) <= "100";
                            end if;
                            if(lights=2) then
                                led_out(2 downto 0) <= "100";
                            end if;
                            if(lights=3) then
                                led_out(2 downto 0) <= "100";
                            end if;
                            if(lights=4) then
                                lights 			<= 0;
                                startprocess 	<= startprocess + 1;
                            end if;
                        end if;

					end if;

				elsif(TrackExists = '1' and TrackOK = '1') then
					
					if(lights=0) then
						lights <= lights + 1;
					end if;
					if(lights=1) then
						led_out(2 downto 0) <= "001";
					end if;
					if(lights=2) then
						led_out(2 downto 0) <= "001";
					end if;
					if(lights=3) then
						led_out(2 downto 0) <= "001";
					end if;
					if(lights=4) then
						lights 			<= 0;
						startprocess 	<= startprocess + 1;
					end if;

				else

					if(lights=0) then
						lights <= lights + 1;
					end if;
					if(lights=1) then
						led_out(2 downto 0) <= "001";
					end if;
					if(lights=2) then
						led_out(2 downto 0) <= "001";
					end if;
					if(lights=3) then
						led_out(2 downto 0) <= "001";
					end if;
					if(lights=4) then
						lights 			<= 0;
						startprocess 	<= startprocess + 1;
					end if;
				end if;

			end if;	
		end if;
	end process;
	

	enc: encrypter port map (
		clock => clk_in,
		K => key,
		P => plaintext,
		C => ciphertext,
		done => enc_done,
        reset => enc_reset,
        enable => enc_enable
	);

	dec: decrypter port map (
		clock => clk_in,
		K => key,
        C => encrypted_message,
        P => decrypted_message,
        done => dec_done,
        reset => dec_reset,
		enable => dec_enable
	);
	
	
	-- Select values to return for each channel when the host is reading

	f2hData_out <= 
			 encrypted_ack( 7 downto 0) 	when (chanAddr_in = chanwrite and (microstate0 = 12 or microstate0 = 27 or microstate0 = 36) and outcnt = 0)
		else encrypted_ack(15 downto 8)  	when (chanAddr_in = chanwrite and (microstate0 = 12 or microstate0 = 27 or microstate0 = 36) and outcnt = 1)
		else encrypted_ack(23 downto 16) 	when (chanAddr_in = chanwrite and (microstate0 = 12 or microstate0 = 27 or microstate0 = 36) and outcnt = 2)
		else encrypted_ack(31 downto 24) 	when (chanAddr_in = chanwrite and (microstate0 = 12 or microstate0 = 27 or microstate0 = 36) and outcnt = 3)
		else encrypted_position( 7 downto 0) 	when (chanAddr_in = chanwrite and microstate0 = 3 and outcnt = 0)
		else encrypted_position(15 downto 8) 	when (chanAddr_in = chanwrite and microstate0 = 3 and outcnt = 1)
		else encrypted_position(23 downto 16) 	when (chanAddr_in = chanwrite and microstate0 = 3 and outcnt = 2)
		else encrypted_position(31 downto 24) 	when (chanAddr_in = chanwrite and microstate0 = 3 and outcnt = 3)
		else data_on_fpga when(chanAddr_in = chanwrite and microstate1 = 3)
        else data_on_uart when(chanAddr_in = "0001010")
        else "10000000";

	-- Assert that there's always data for reading, and always room for writing
	f2hValid_out <= '1';
	h2fReady_out <= '1';                                                     
	
	
	--END_SNIPPET(registers)

	flags <= "00" & f2hReady_in & reset_in;
	seven_seg : entity work.seven_seg
			port map(
				clk_in     => clk_in,
				data_in    => checksum,
				dots_in    => flags,
				segs_out   => sseg_out,
				anodes_out => anode_out
			);
		
end architecture;
