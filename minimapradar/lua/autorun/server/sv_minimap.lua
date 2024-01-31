util.AddNetworkString("DeathsUpdate")

hook.Add("PlayerDeath", "DeathHandler", function(victim) 

    net.Start("DeathsUpdate")
    net.WriteVector(victim:GetPos())
    for _, curPly in ipairs(player.GetAll()) do
        net.Send(curPly)
    end

end)