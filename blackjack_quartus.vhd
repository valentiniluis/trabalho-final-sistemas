library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

entity blackjack is
    port(
		  -- clk = key(0)
        key : in std_logic_vector(3 downto 0);
		  -- sw(0) = start
		  -- sw(1) = hit
		  -- sw(2) = stay
		  -- sw(3) = random
        sw : in std_logic_vector(9 downto 0);
		  
		  -- sw(9 downto 6) = cards
        -- sw(9 downto 6) : in std_logic_vector(3 downto 0);
        
		  -- ledr(0) = win
		  -- ledr(1) = lose
		  -- ledr(2) = tie
        ledr : out std_logic_vector(9 downto 0);
		  
		  -- hex0 = sum_player_d1
		  -- hex1 = sum_player_d2
		  -- hex3 = card
        hex3, hex0, hex1, hex2 : out std_logic_vector(6 downto 0)
    );
end blackjack;

architecture behav of blackjack is
    signal soma_player, soma_dealer, as_player, as_dealer : integer := 0;
    signal game_over : std_logic := '0';
    signal inicio_jogo : std_logic := '1';

    type estado is (inicio, nova_carta_player, nova_carta_dealer, escolha_player, escolha_dealer, decidir_vencedor, empatou, perdeu, venceu);

	 type integer_vector is array (natural range <>) of integer;
    signal array_cartas : integer_vector(51 downto 0);
    signal estado_atual : estado;

    -- número aleatório
    signal lfsr : std_logic_vector(5 downto 0) := "000001";
    signal feedback : std_logic;

begin

    feedback <= not(lfsr(5) xor lfsr(4));
	 hex2 <= "1111111";

    process(key, sw(0))
    
    -- variáveis auxiliares para controlar a quantidade de ases e soma do jogador e dealer 
    variable aux_soma_player : integer := soma_player;
    variable aux_soma_dealer : integer := soma_dealer;
    variable aux_as_player : integer := as_player;
    variable aux_as_dealer : integer := as_dealer;

    -- variáveis para geração do número aleatório
    
    variable lfsr_i : std_logic_vector(5 downto 0) := lfsr;
    variable int_rand : integer;

    -- variável que receberá a entrada 'sw(9 downto 6)' ou uma carta aleatória, dependendo do input do usuário
    variable carta_atual : integer := 0;
    
    begin

        if (sw(0)='1') then
            estado_atual <= inicio;
            inicio_jogo <= '1';
            game_over <= '0';
            soma_player <= 0;
            soma_dealer <= 0;
            aux_as_dealer := 0;
            aux_as_player := 0;
            aux_soma_dealer := 0;
            aux_soma_player := 0;
            ledr(0) <= '0';
            ledr(1) <= '0';
            ledr(2) <= '0';
            hex3 <= "1000000";

            for valor in 0 to 51 loop
                array_cartas(valor) <= 1 + (valor mod 13);
            end loop;

        elsif (key(0)'event and key(0)='0' and game_over='0') then

            if (estado_atual=nova_carta_dealer or estado_atual=nova_carta_player) then
                if (sw(3)='0') then
                    carta_atual := to_integer(unsigned(sw(9 downto 6)));
                else
                    -- geração de índice de carta aleatório
                    lfsr_i := lfsr_i(4 downto 0) & feedback;
                    int_rand := to_integer(unsigned(lfsr_i));
                    
                    -- se o índice for maior que 51 (tamanho do vetor de cartas), então subtraimos um valor aleatório do índice
                    if (int_rand>51) then
                        int_rand := int_rand - soma_player - soma_dealer - 12;
                    end if;
                    
                    -- se o índice do vetor já tiver sido usado no presente jogo, outro índice aleatório é gerado
                    if (array_cartas(int_rand)=0) then
                        lfsr_i := lfsr_i(4 downto 0) & feedback;
                        int_rand := to_integer(unsigned(lfsr_i));
                        if (int_rand>51) then
                            int_rand := int_rand - soma_player - soma_dealer - 12;
                        end if;
                    end if;

                    carta_atual := array_cartas(int_rand);
                    array_cartas(int_rand) <= 0;
                    lfsr <= lfsr_i;
                
					 end if;
            end if;

            case estado_atual is
                when inicio =>
                        estado_atual <= nova_carta_player;
                         
                when nova_carta_player =>

                    if (carta_atual=1) then
                        aux_soma_player := soma_player + 11;
                        aux_as_player := aux_as_player + 1;
                    elsif (carta_atual=11 or carta_atual=12 or carta_atual=13) then
                        aux_soma_player := soma_player + 10;
                    else
                        aux_soma_player := soma_player + carta_atual;
                    end if;

                    if (aux_soma_player>21 and aux_as_player>0) then
                        aux_soma_player := aux_soma_player - 10;
                        aux_as_player := aux_as_player - 1;
                    end if;

                    soma_player <= aux_soma_player;
                    as_player <= aux_as_player;

                    if (inicio_jogo='1') then
                        estado_atual <= nova_carta_dealer;
                    else
                        estado_atual <= escolha_player;
                    end if;
						  
						  case carta_atual is
                        when 1 => hex3 <= "1111001"; 
                        when 2 => hex3 <= "0100100"; 
                        when 3 => hex3 <= "0110000"; 
                        when 4 => hex3 <= "0011001"; 
                        when 5 => hex3 <= "0010010"; 
                        when 6 => hex3 <= "0000010"; 
                        when 7 => hex3 <= "1111000"; 
                        when 8 => hex3 <= "0000000";     
                        when 9 => hex3 <= "0010000";
                        when 10 => hex3 <= "0001000";
                        when 11 => hex3 <= "0000011";
                        when 12 => hex3 <= "0100111";
                        when 13 => hex3 <= "0100001";
                        when others => hex3 <= "1000000";
                    end case;
                
                when nova_carta_dealer =>

                    if (carta_atual=1) then
                        aux_soma_dealer := soma_dealer + 11;
                        aux_as_dealer := aux_as_dealer + 1;
                    elsif (carta_atual=11 or carta_atual=12 or carta_atual=13) then
                        aux_soma_dealer := soma_dealer + 10;
                    else
                        aux_soma_dealer := soma_dealer + carta_atual;
                    end if;

                    if (aux_soma_dealer>21 and aux_as_dealer>0) then
                        aux_soma_dealer := aux_soma_dealer - 10;
                        aux_as_dealer := aux_as_dealer - 1;
                    end if;

                    soma_dealer <= aux_soma_dealer;
                    as_dealer <= aux_as_dealer;
                    
                    if (inicio_jogo='0') then
                        estado_atual <= escolha_dealer;
                    elsif (soma_dealer>0) then
                        inicio_jogo <= '0';
                        estado_atual <= escolha_player;
                    else
                        estado_atual <= nova_carta_player;
                    end if;

                when escolha_player =>
                    if (sw(1)='1') then
                        estado_atual <= nova_carta_player;
                    elsif (sw(2)='1') then
                        estado_atual <= escolha_dealer;
                    end if;

                when escolha_dealer => 
                    if (soma_dealer>=17) then
                        estado_atual <= decidir_vencedor;
                    else
                        estado_atual <= nova_carta_dealer;
                    end if;

                when decidir_vencedor =>
                    if (soma_player>soma_dealer) then
                        estado_atual <= venceu;
                    elsif (soma_player=soma_dealer) then
                        estado_atual <= empatou;
                    else
                        estado_atual <= perdeu;
                    end if;
                    
                when others =>
                    game_over <= '1';

            end case;
        end if;

        if (aux_soma_player=21 or (aux_soma_dealer>21 and aux_as_dealer=0)) then
            ledr(0) <= '1';
            estado_atual <= venceu;
            --game_over <= '1';

        elsif (aux_soma_dealer=21 or (aux_soma_player>21 and aux_as_player=0)) then
            ledr(1) <= '1';
            estado_atual <= perdeu;
            --game_over <= '1';

        elsif (estado_atual=decidir_vencedor) then
            if (aux_soma_player>aux_soma_dealer) then
                ledr(0) <= '1';
            elsif (aux_soma_dealer>aux_soma_player) then
                ledr(1) <= '1';
            else
                ledr(2) <= '1';
            end if;
            --game_over <= '1';
        end if;


    end process;

    update_Sums : process(soma_player)
        variable unidade : integer;
    begin
        
        if (soma_player<10) then hex1 <= "1000000";
        elsif (soma_player<20) then hex1 <= "1111001";
        elsif (soma_player<30) then hex1 <= "0100100";
        else hex1 <= "0110000";
        end if;

        unidade := soma_player rem 10;
        case unidade is
				when 1 => hex0 <= "1111001"; 
				when 2 => hex0 <= "0100100"; 
				when 3 => hex0 <= "0110000"; 
				when 4 => hex0 <= "0011001"; 
				when 5 => hex0 <= "0010010"; 
				when 6 => hex0 <= "0000010"; 
				when 7 => hex0 <= "1111000"; 
				when 8 => hex0 <= "0000000";     
				when 9 => hex0 <= "0010000";
				when others => hex0 <= "1000000";
        end case;

    end process;

end behav;