* Paso 1: Importar datos
import excel using "C:/Users/Nuria/Desktop/UNI/2023-2024_UNI/EM/Proyecto/STATA/CIS_data.xlsx", firstrow clear

* Paso 2: Generar preferencias de voto iniciales
gen chosen_party = .
foreach var in p_1 p_2 p_3 p_4 p_5 {
    replace chosen_party = `var' if `var' > chosen_party | missing(chosen_party)
}

gen previous_chosen_party = chosen_party

* Definir el efecto de los medios
local media_effect_p_1 = (runiform() - 0.5) * 2
local media_effect_p_2 = (runiform() - 0.5) * 2
local media_effect_p_3 = (runiform() - 0.5) * 2
local media_effect_p_4 = (runiform() - 0.5) * 2
local media_effect_p_5 = (runiform() - 0.5) * 2

* Paso 3: Simulación de voto
local continue = 1
local iteration = 0
while `continue' {
	local iteration = `iteration' + 1
	
	display "Iteracion: " `iteration'
	
	replace p_1 = p_1 + `media_effect_p_1'
	replace p_2 = p_2 + `media_effect_p_2'
	replace p_3 = p_3 + `media_effect_p_3'
	replace p_4 = p_4 + `media_effect_p_4'
	replace p_5 = p_5 + `media_effect_p_5'
	
	 * Calcular la distancia de proximidad de Downs
	foreach var in p_1 p_2 p_3 p_4 p_5 {
		gen distance_`var' = -(v_i - `var')^2
	}
	
    * Reevaluar la preferencia de voto después de la proximidad de Downs
    foreach var in p_1 p_2 p_3 p_4 p_5 {
        replace chosen_party = `var' if distance_`var' == min(distance_p_1, distance_p_2, distance_p_3, distance_p_4, distance_p_5)
    }

    * Verificar si algún partido alcanza mayoría absoluta
    local majority = _N/2+1
    foreach var in p_1 p_2 p_3 p_4 p_5 {
        count if chosen_party == `var'
        if r(N) > `majority' {
            display "Mayoría absoluta alcanzada por partido `var'"
            local continue = 0
            break
        }
    }
	export excel p_1 p_2 p_3 p_4 p_5 using "C:/Users/Nuria/Desktop/UNI/2023-2024_UNI/EM/Proyecto/STATA/out_final.xlsx", replace
    count if chosen_party != previous_chosen_party
    if r(N) == 0 {
        display "Ningún agente cambió de opinión. Terminando la simulación."
        local continue = 0
    }

    * Actualizar la variable de voto anterior para la próxima iteración
    replace previous_chosen_party = chosen_party

    * Si no hay cambios o se alcanza la mayoría, terminar la simulación
    if `continue' == 0 {
        break
    }
}

display "Numero total de iteraciones", `iteration'



