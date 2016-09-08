#!/bin/bash

#--------------------------------------------------------#
# Data: 7 de setembro de 2016
# Criado por: Juliano Santos [x_SHAMAN_x]
# Script: ecron.sh
# Descrição: Permite gerenciar os agendamentos do 'CRON'
# -------------------------------------------------------#

# Suprime erros
exec 2>/dev/null

# Script
SCRIPT=$(basename "$0")

# Mensagem de erro
err_msg(){ echo "$SCRIPT: erro: '$1' não está instalado." 1>&2; exit 1; }

# Binários
CRONTAB="$(which crontab)"
YAD="$(which yad)"

# Verifica se os comandos estão presentes.
[ -x "$CRONTAB" ] || err_msg "crontab"
[ -x "$YAD" ] || err_msg "yad"

# Se o script foi executado com argumentos
[ "$1" == "schedule" ] && { schedule $2 ${*:3}; exit 0; }

# Arquivo onde será armazenado os agendamentos do 'CRON'
CONF=/tmp/cron.conf

# Arquivos temporários
export TMP_CONF=/tmp/cron.tmp
export TMP_HOUR=/tmp/hour.dat
export TMP_MIN=/tmp/min.dat
export TMP_DAY=/tmp/day.dat
export TMP_MONTH=/tmp/month.dat
export TMP_WEEK=/tmp/week.dat
export TMP_CMD=/tmp/cmd.dat

# Limpa os intervalos de campos da janela.
setval_field(){	eval printf '%d:$1\\n' $(seq $2 $3 $4); }

schedule()
{
	# Variáveis locais
	local -a DT_HOUR DT_MIN DT_DAY DT_MONTH DT_WEEK
	
	# Lê o parâmetro da função
	# Parâmetros: 'open' ou 'new'
	case $1 in
		open)
			# Editar agendamento
			# Armazena o 'fd' de saida.
			OUT=/dev/stdout
				
			# Armazena os valores passados na função
			# HTMP = HORAS; MTMP = MINUTOS; DTMP = DIAS; MMTMP = MESES; WTMP = DIAS DA SEMANA
			HTMP=$2; MTMP=$3; DTMP=$4; MMTMP=$5; WTMP=$6
			DT_CMD="${*:7}"		# Linha de comando

			# Define o delimitador
			IFS=','

			# Lẽ os elementos e armazena o status do 'checkbox' nos vetores correspondentes.
			for H in $HTMP; do DT_HOUR[$H]=TRUE; done
			for M in $MTMP; do DT_MIN[$M]=TRUE; done
			for D in $DTMP; do DT_DAY[$D]=TRUE; done
			for MM in $MMTMP; do DT_MONTH[$MM]=TRUE; done
			for W in $WTMP; do DT_WEEK[$W]=TRUE; done

			# Altera as propriedades da janela.
			WIN_TITLE='Editar agendamento'
			BTN_LABEL="Aplicar"
			BTN_ICON='gtk-apply'
			TOOLTIP='Aplica as alterações.'
			BTN_DEL='--button=''Excluir!gtk-delete'':2'

			# Limpa as variáveis.
			unset IFS HTMP MTMP DTMP MMTMP WTMP
			;;
		new)
			# Novo agendamento
			# Define as propriedades da janela.
			WIN_TITLE='Novo agendamento'
			BTN_LABEL='Adicionar'
			BTN_ICON='gtk-add'
			TOOLTIP='Adiciona novo agendamento.'
			unset BTN_DEL
			OUT=$CONF	# Salva a saida no arquivo
			;; 
	esac
	
	################## CRIA A JANELA COM MULTIPLAS ABAS ##################################
	# Cria estrutura da aba e carrega os valores dos 'checkboxs', redirecionando
	# a saida para seus respectivos arquivos temporários.
	# Todos as abas são executadas em background, sendo referenciadas pelo seu código 'PLUG'
	
	# Aba: Horas
	unset FIELD; for i in {0..23}; do FIELD+="--field=$i:CHK ${DT_HOUR[$i]:-FALSE} "; done

	$YAD --plug=$$ \
        --tabnum=1 \
        --form \
        --columns=4 \
        --text='<b>Intervalos:\t\t\t\t\t\t\tHoras:</b>' \
        --field='1 hora':BTN "@ bash -c 'setval_field TRUE 9 1 32'" \
        --field='2 horas':BTN "@ bash -c 'setval_field FALSE 9 1 32; setval_field TRUE 9 2 32'" \
        --field='3 horas':BTN "@ bash -c 'setval_field FALSE 9 1 32; setval_field TRUE 9 3 32'" \
        --field='5 horas':BTN "@ bash -c 'setval_field FALSE 9 1 32; setval_field TRUE 9 5 32'" \
        --field='8 horas':BTN "@ bash -c 'setval_field FALSE 9 1 32; setval_field TRUE 9 8 32'" \
        --field='Hora par':BTN "@ bash -c 'setval_field FALSE 9 1 32; setval_field TRUE 9 2 32'" \
        --field='Hora impar':BTN "@ bash -c 'setval_field FALSE 9 1 32; setval_field TRUE 10 2 32'" \
        --field='Limpar':BTN "@ bash -c 'setval_field FALSE 9 1 32'" \
		$FIELD &> $TMP_HOUR &
	
	# Aba: Minutos
	unset FIELD; for i in {0..59}; do FIELD+="--field=$i:CHK ${DT_MIN[$i]:-FALSE} "; done
		
	$YAD --plug=$$ \
		--tabnum=2 \
		--form \
		--columns=10 \
		--text='<b>Intervalos:\t\t\t\t\t\t\tMinutos:</b>' \
		--field='1 Minuto':BTN "@ bash -c 'setval_field TRUE 8 1 67'" \
		--field='5 Minutos':BTN "@ bash -c 'setval_field FALSE 8 1 67; setval_field TRUE 8 5 67'" \
		--field='10 Minutos':BTN "@ bash -c 'setval_field FALSE 8 1 67; setval_field TRUE 8 10 67'" \
		--field='15 Minutos':BTN "@ bash -c 'setval_field FALSE 8 1 67; setval_field TRUE 8 15 67'" \
		--field='30 Minutos':BTN "@ bash -c 'setval_field FALSE 8 1 67; setval_field TRUE 8 30 67'" \
		--field='45 Minutos':BTN "@ bash -c 'setval_field FALSE 8 1 67; setval_field TRUE 8 45 67'" \
		--field='Limpar':BTN "@ bash -c 'setval_field FALSE 8 1 67'" \
		$FIELD &> $TMP_MIN &
	
	# Aba: Dias
	unset FIELD; for i in {1..31}; do FIELD+="--field=$i:CHK ${DT_DAY[$i]:-FALSE} "; done
	
	$YAD --plug=$$ \
		--tabnum=3 \
		--form \
		--columns=6 \
		--text='<b>Intervalos:\t\t\t\t\t\t\tDias:</b>' \
		--field='1 Dia':BTN "@ bash -c 'setval_field TRUE 8 1 38'" \
		--field='2 Dias':BTN "@ bash -c 'setval_field FALSE 8 1 38; setval_field TRUE 8 2 38'" \
		--field='7 Dias':BTN "@ bash -c 'setval_field FALSE 8 1 38; setval_field TRUE 8 7 38'" \
		--field='15 dias':BTN "@ bash -c 'setval_field FALSE 8 1 38; setval_field TRUE 8 15 38'" \
		--field='Dia par':BTN "@ bash -c 'setval_field FALSE 8 1 38; setval_field TRUE 9 2 38'" \
		--field='Dia impar':BTN "@ bash -c 'setval_field FALSE 8 1 38; setval_field TRUE 8 2 38'" \
		--field='Limpar':BTN "@ bash -c 'setval_field FALSE 8 1 38'" \
		$FIELD &> $TMP_DAY &

	# Aba: Meses
	unset FIELD
	MM=1

	for i in Janeiro Ferreiro Março Abril Maio Junho Julho Agosto Setembro Outubro Novembro Dezembro; do
		FIELD+="--field=$i:CHK ${DT_MONTH[$MM]:-FALSE} "; ((MM++)); done
	
	$YAD --plug=$$ \
		--tabnum=4 \
		--form \
		--columns=3 \
		--text='<b>Intervalos:\t\t\t\t\t\t\tMeses:</b>' \
		--field='1 Mês':BTN "@ bash -c 'setval_field TRUE 7 1 18'" \
		--field='2 Meses':BTN "@ bash -c 'setval_field FALSE 7 1 18; setval_field TRUE 7 2 18'" \
		--field='3 Meses':BTN "@ bash -c 'setval_field FALSE 7 1 18; setval_field TRUE 7 3 18'" \
		--field='6 Meses':BTN "@ bash -c 'setval_field FALSE 7 1 18; setval_field TRUE 7 6 18'" \
		--field='Limpar':BTN "@ bash -c 'setval_field FALSE 7 1 18'" \
		--field='':LBL '' \
		$FIELD &> $TMP_MONTH &

	# Aba: Dias da semana
	unset FIELD
	W=1

	for i in Segunda-feira Terça-feira Quarta-feira Quinta-feira Sexta-feira Sábado Domingo; do
		FIELD+="--field=$i:CHK ${DT_WEEK[$W]:-FALSE} "; ((W++)); done
	
	$YAD --plug=$$ \
		--tabnum=5 \
		--form \
		--columns=2 \
		--text='<b>Intervalos:\t\t\t\t\t\tDias da semana:</b>' \
		--field='1x p/ semana':BTN "@ bash -c 'setval_field FALSE 9 1 15; setval_field TRUE 9 1 9'" \
		--field='2x p/ semana':BTN "@ bash -c 'setval_field FALSE 9 1 15; setval_field TRUE 9 2 12'" \
		--field='3x p/ semana':BTN "@ bash -c 'setval_field FALSE 9 1 15; setval_field TRUE 9 3 15'" \
		--field='7x p/ semana':BTN "@ bash -c 'setval_field TRUE 9 1 15'" \
		--field='Limpar':BTN "@ bash -c 'setval_field FALSE 9 1 15'" \
		--field='':LBL '' \
		--field='':LBL '' \
		--field='':LBL '' \
		$FIELD &> $TMP_WEEK &

	# Aba: Executar
	$YAD --plug=$$ \
		--tabnum=6 \
		--form \
		--text='<b>Comandos:</b>' \
		--field='' "$DT_CMD" &> $TMP_CMD &

	# Form Principal
	$YAD --notebook \
		--key=$$ \
		--tab='Horas' --tab='Minutos' --tab='Dias' --tab='Meses' --tab='Dias da semana' --tab='Executar' \
		--center \
		--fixed \
		--title="$WIN_TITLE" \
		--button='Voltar!undo':1 \
		$BTN_DEL \
		--button=$BTN_LABEL'!'$BTN_ICON'!'"$TOOLTIP":0 

	# Retorno da janela
	RETVAL=$?

	# Salvar 
	if [ $RETVAL -eq 0 ]; then
		# Extrai dos arquivos temporários os status dos checkbox's
		# e inicializa os arrays
		HVAL=0; HSTR=; HCHK=($(cat $TMP_HOUR | tr '|' ' '))			# Horas 
		MVAL=0; MSTR=; MCHK=($(cat $TMP_MIN | tr '|' ' '))			# Minutos
		DVAL=1; DSTR=; DCHK=($(cat $TMP_DAY | tr '|' ' '))			# Dias
		MMVAL=1; MMSTR=; MMCHK=($(cat $TMP_MONTH | tr '|' ' ')) 	# Meses
		WVAL=1; WSTR=; WCHK=($(cat $TMP_WEEK | tr '|' ' '))			# Dias da semana.

		CSTR="$(cat $TMP_CMD)"										# comandos

		# Lê a posição dos elementos no array, incrementando a variavel com o numero do indice.
		for ITEM in ${HCHK[@]};	do [[ $ITEM == "TRUE" ]] && HSTR+="$HVAL,"; ((HVAL++)); done
		for ITEM in ${MCHK[@]};	do [[ $ITEM == "TRUE" ]] && MSTR+="$MVAL,"; ((MVAL++)); done
		for ITEM in ${DCHK[@]};	do [[ $ITEM == "TRUE" ]] && DSTR+="$DVAL,"; ((DVAL++)); done
		for ITEM in ${MMCHK[@]}; do [[ $ITEM == "TRUE" ]] && MMSTR+="$MMVAL,"; ((MMVAL++)); done
		for ITEM in ${WCHK[@]}; do [[ $ITEM == "TRUE" ]] && WSTR+="$WVAL,"; ((WVAL++)); done
	
		# Remove os delimitadores do final da string
		HSTR=$(echo $HSTR | sed 's/,$//')
		MSTR=$(echo $MSTR | sed 's/,$//')
		DSTR=$(echo $DSTR | sed 's/,$//')
		MMSTR=$(echo $MMSTR | sed 's/,$//')
		WSTR=$(echo $WSTR | sed 's/,$//')
		CSTR="$(echo "$CSTR" | sed 's/|$//')"
	
		# Imprime os campos do agendamento
		printf '%s\n%s\n%s\n%s\n%s\n%s\n' $HSTR $MSTR $DSTR $MMSTR $WSTR "$CSTR" >> $OUT 
	elif [ $RETVAL -eq 2 ]; then
		# Excluir
		$YAD --form \
			--center \
			--fixed \
			--on-top \
			--image=gtk-dialog-warning \
			--title='Excluir' \
			--text='Essa ação excluirá o agendamento atual.\nDeseja continuar ?' \
			--button='Sim':0 \
			--button='Não':1

		# Limpa a coluna selecionada 
		[ $? -eq 0 ] && printf '\n\n\n\n\n\n'
	fi
			
}

# Exporta as funções para que possam ser executadas pelo yad
export -f setval_field
export -f schedule

# Status de leitura das configurações cron.
# 0 - Lê os agendamentos atuais.
# 1 - Lê os agendamentos atuais+temporários
INI=0

while :
do
	# Remove arquivo temporário (se ele existir)
	rm $TMP_CONF

	if [ $INI -eq 0 ]; then
		# Lê as configurações atuais do 'CRON' e salva em 'CONF'
		$CRONTAB -l | \
		egrep -v "^$|^ *$|^[[:blank:]]*#" | \
		awk '{cmd=""; for(i=1;i<=NF;i++) if (i>5) cmd=cmd $i" "; printf "%s\n%s\n%s\n%s\n%s\n%s\n",$2,$1,$3,$4,$5,cmd }' > $CONF
		# Não lê novamente as configurações
		INI=1
	fi

	# Janela principal
	cat $CONF | $YAD --title="$SCRIPT - [x_SHAMAN_x]" \
				--text="O <b>$SCRIPT</b> permite adicionar, editar e excluir agendamentos. Para editar um agendamento existente, basta clicar 2x sobre ele.\nSe deseja excluir um agedamento, entre no modo de edição e depois clique em <b>[Excluir]</b>.\nPara criar um novo agendamento, clique em <b>[Novo]</b>.\nPara desfazer uma alteração não salva, clique em <b>[Desfazer]</b>\nOBS: TODOS OS CAMPOS SÃO OBRIGATÓRIOS\n\n<b>Total: $(($(cat $CONF | wc -l)/6))</b>" \
				--center \
				--fixed \
				--image=calendar \
				--width=900 \
				--height=500 \
				--list \
				--separator='#' \
				--print-all \
				--dclick-action="@$0 schedule open" \
				--column='Hora(s)' \
				--column='Minuto(s)' \
				--column='Dia(s) do mês' \
				--column='Mes(es)' \
				--column='Dia(s) da semana' \
				--column='Comando(s)' \
				--button='Sair!gtk-quit!Sai do script.':1 \
				--button='Desfazer!undo':3 \
				--button='Novo!gtk-new!Cria um novo agendamento.':2 \
				--button='Salvar!gtk-save!Salvas as alterações.':0 | \
				awk -F'#' '{printf "%s %s %s %s %s %s\n",$2,$1,$3,$4,$5,$6}' >> $TMP_CONF 

	# Lê o código de retorno da janela
	RETVAL=${PIPESTATUS[1]}

	# Lê o retorno
	case $RETVAL in
		1|252)
			# Finaliza o script
			exit 0
			;;	
		2)
			# Novo agendamento
			schedule new
			;;
		0)
			# Salvar as configurações
			if ! $CRONTAB -u $USER $TMP_CONF; then
				# Se houver campos inválidos, envia mensagem de erro
				$YAD --form \
						--center \
						--on-top \
						--fixed \
						--image=gtk-dialog-error \
						--title='Erro' \
						--text='Não foi possível salvar as alterações.\nO agendamento possui campos inválidos.' \
						--button='OK':0; fi
			INI=0	# Lê as configurações
			;;
		3)
			# Desfazer
			INI=0	# Lê as configurações
			;;
	esac
done
# FIM
