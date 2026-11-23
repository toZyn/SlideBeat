local M = {}
M.windows = {0.065, 0.12, 0.18}
function M.direction(x, y, radius)
    if x*x + y*y < radius*radius then return nil end
    if math.abs(x) > math.abs(y) then return x > 0 and 4 or 3 end
    return y > 0 and 2 or 1
end
function M.chart(level)
    local notes = {}
    local pattern = {1, 4, 2, 3, 1, 3, 2, 4, 4, 1, 3, 2, 3, 4, 1, 2}
    local step = ({1, 0.5, 0.25})[level]
    for beat = 8, 87, step do
        local index = #notes + 1
        notes[index] = {time = beat * 0.5, direction = pattern[(index-1)%#pattern+1]}
    end
    return notes
end
function M.new(level)
    return {notes = M.chart(level), index = 1, score = 0, combo = 0, best = 0, hits = 0, misses = 0, weight = 0, judged = 0}
end
function M.judge(game, grade)
    game.judged = game.judged + 1
    if grade then
        game.hits = game.hits + 1
        game.combo = game.combo + 1
        game.best = math.max(game.best, game.combo)
        local weight = ({1, 0.7, 0.4})[grade]
        game.weight = game.weight + weight
        game.score = game.score + math.floor(1000 * weight)
    else
        game.misses = game.misses + 1
        game.combo = 0
    end
    game.index = game.index + 1
end
function M.update(game, time)
    local count = 0
    while game.notes[game.index] and time - game.notes[game.index].time > M.windows[3] do
        M.judge(game, nil)
        count = count + 1
    end
    return count
end
function M.hit(game, direction, time)
    M.update(game, time)
    local note = game.notes[game.index]
    if not note or math.abs(time-note.time) > M.windows[3] then return 'EARLY' end
    if note.direction ~= direction then M.judge(game, nil) return 'WRONG' end
    local delta = math.abs(time-note.time)
    local grade = delta <= M.windows[1] and 1 or delta <= M.windows[2] and 2 or 3
    M.judge(game, grade)
    return ({'PERFECT', 'GOOD', 'LATE / EARLY'})[grade]
end
function M.accuracy(game)
    return game.judged == 0 and 100 or game.weight/game.judged*100
end
return M
