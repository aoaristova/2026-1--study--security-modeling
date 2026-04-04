using DrWatson
@quickactivate "project"
using Distributions
using Statistics
using JLD2
include(srcdir("simulation.jl"))

params = Dict(
    :λ => 5.0,
    :T => 24.0,
    :num_hours_for_est => 10000  # количество 8-часовых смен для оценки
)

function run_simulation(p)
    @unpack λ, T, num_hours_for_est = p
    
    # Основная симуляция
    res = simulate_attacks(λ, T)
    
    # Вероятность: ни одной атаки за смену (8 часов)
    # Интервалы по 30 минут 
    half_hour_counts = rand(Poisson(λ * 0.5), num_hours_for_est)
    emp_prob = count(half_hour_counts .>= 3) / num_hours_for_est
    theor_prob = 1 - cdf(Poisson(λ * 0.5), 2)  # P(≥3) = 1 - P(≤2)
    
    
    return Dict(
        :hourly_counts => res.hourly_counts,
        :intervals => res.intervals,
        :attack_times => res.attack_times,
        :emp_prob => emp_prob,
        :theor_prob => theor_prob
    )
end

# Генерируем имя файла
filename = datadir("attack_sim_3_for_30min", savename(params, "jld2"))
mkpath(datadir("attack_sim_3_for_30min"))

# Проверяем существование файла
if isfile(filename)
    println("Загрузка существующих данных из $filename")
    data = load(filename)["data"]
else
    println("Запуск симуляции...")
    data = run_simulation(params)
    println("Сохраняем в файл...")
    @save filename data
    println("Результаты сохранены в $filename")
end

# Вывод результатов
println("Вероятность: ни одной атаки за 8-часовую смену")
println("Эмпирическая: ", data[:emp_prob])
println("Теоретическая: ", data[:theor_prob])
