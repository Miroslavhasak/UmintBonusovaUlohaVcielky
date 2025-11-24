clear; clc; close all;

% parametre
pop_size = 50;                  
pocetPremennych = 10;           
max_iters = 5000;               
space_min = -500;               
space_max = 500;                
limit = 100;                    
runs = 5;                       

history_abc_all = zeros(max_iters, runs);
history_ga_all = zeros(max_iters, runs);

%% cykly pre vypisovanie
for run = 1:runs
    [~, best_fitness_abc, history_abc] = abc_schwefel(pop_size, pocetPremennych, max_iters, limit, space_min, space_max);
    history_abc_all(:, run) = history_abc;
    fprintf('%d. ABC, najlepsie fitness: %.4f\n', run, best_fitness_abc);
end

for run = 1:runs
    [~, best_fitness_ga, history_ga] = ga_schwefel();
    history_ga_all(:, run) = history_ga;
    fprintf('%d. GA, najlepsie fitness: %.4f\n', run, best_fitness_ga);
end

% priemerny priebeh fitness funkcie pre ABC a GA
mean_history_abc = mean(history_abc_all, 2);
mean_history_ga = mean(history_ga_all, 2);

% vykreslenie vysledkov
figure;
hold on;
title('Porovnanie ABC a GA na Schwefelovej funkcii');
xlabel('Iteracie');
ylabel('Najlepsia fitness hodnota');
plot(1:max_iters, mean_history_abc, 'b', 'LineWidth', 2);
plot(1:max_iters, mean_history_ga, 'g', 'LineWidth', 2);
legend('ABC (priemer)', 'GA (priemer)');
grid on;
hold off;

%% ABC
function [best_solution, best_fitness, history] = abc_schwefel(pop_size, n_var, max_iters, limit, space_min, space_max)

    population = space_min + rand(pop_size, n_var) * (space_max - space_min);
    fitness = testfn3(population);
    trial = zeros(pop_size, 1); % sleduje kolkokrat sa neuspesne pokusila vcela zlepsit poziciu
    history = zeros(max_iters, 1);

    for iter = 1:max_iters
        % prieskum novych rieseni pre kazdu robotnicu
%% robotnice
        for i = 1:pop_size
            [~, best_idx] = min(fitness);  % hladanie najlepsieho riesenia
            if best_idx == i % i je index aktualnej vcely 
                k = randi([1, pop_size]);  % vyhneme sa zvoleniu toho isteho jedinca
            else
                k = best_idx;
            end
            
            nahodnySmer = rand(1, n_var) * 2 - 1; % generovanie nahodnych hodnot v rozsahu [-1, 1]
% vytvorenie noveho jedinca pomocou aktualnej polohy a inej polohy 
            candidate = population(i, :) + nahodnySmer .* (population(i, :) - population(k, :));  
            candidate = max(min(candidate, space_max), space_min);  % hranice
            candidate_fitness = testfn3(candidate); % generovanie fitness

            % ak je novy kandidat lepsi tak ho aktualizujeme
            if candidate_fitness < fitness(i)
                population(i, :) = candidate;
                fitness(i) = candidate_fitness;
                trial(i) = 0;  % reset trial
            else
                trial(i) = trial(i) + 1;  % pridame trial
            end
        end

        % prieskumnici ak trial je vacsia ako limit vcela je unavena a najde
        % sa nova nahodna pozicia pre vcelu
%% pozorovatelky
prob = 1 ./ (1 + fitness);    % vytvorenie pravdepodobnosti z fitness
prob = prob ./ sum(prob);     % normalizacia pravdepodobnosti

for i = 1:pop_size
            
            % vyber zdrojovej vcely pomocou roulette wheel
            idx = rouletteWheel(prob);

            % nahodny smer
            k = randi([1 pop_size]);
            while k == idx
                k = randi([1 pop_size]);
            end
            
            nahodnySmer = rand(1, n_var) * 2 - 1;
            candidate = population(idx, :) + nahodnySmer .* (population(idx, :) - population(k, :));
            candidate = max(min(candidate, space_max), space_min);
            candidate_fitness = testfn3(candidate);

            % ak je kandidat lepsi → aktualizujeme zdrojovu vcelu
            if candidate_fitness < fitness(idx)
                population(idx, :) = candidate;
                fitness(idx) = candidate_fitness;
                trial(idx) = 0;
            else
                trial(idx) = trial(idx) + 1;
            end
end
%% prieskumnicky
        for i = 1:pop_size

            if trial(i) > limit
                population(i, :) = space_min + rand(1, n_var) * (space_max - space_min);  % vytvorime nove riesenie
                fitness(i) = testfn3(population(i, :));  % aktualizujeme fitness
                trial(i) = 0;  % reset trial
            end
        end
        
        % ulozenie historie najlepsiej fitness
        [best_fitness, best_idx] = min(fitness);
        history(iter) = best_fitness;
    end
    
    % najlepsie riesenie
    best_solution = population(best_idx, :);
end
%% funkcia roulettewheel
function idx = rouletteWheel(prob)
    r = rand();
    cum = cumsum(prob);
    idx = find(r <= cum, 1, 'first');
end

%% GA
function [best_solution, best_fitness, ga_history] = ga_schwefel()

    pop_size = 50;          
    n_var = 10;             
    max_iters = 5000;       
    crossover_points = 2;   
    mutation_rate = 0.2;    
    space_min = -500; space_max = 500;  

    % inicializacia populacie
    space = [space_min * ones(1, n_var); space_max * ones(1, n_var)];
    population = genrpop(pop_size, space); 
    fitness = testfn3(population);         
    [best_fitness, idx] = min(fitness);
    best_solution = population(idx, :);

    ga_history = zeros(max_iters, 1);

    % GA loop
    for iter = 1:max_iters

        selected_pop = selbest(population, fitness, round(pop_size / 2));  % Selekcia polovice populacie
        offspring = crossov(selected_pop, crossover_points, 0); 
        offspring = mutx(offspring, mutation_rate, space);    

        fitness = testfn3(offspring);

        population = offspring;
        [current_best, idx] = min(fitness);
        if current_best < best_fitness
            best_solution = population(idx, :);
            best_fitness = current_best;
        end

        ga_history(iter) = best_fitness;
    end

end
