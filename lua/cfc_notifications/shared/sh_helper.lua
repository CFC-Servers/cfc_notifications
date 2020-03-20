function CFCNotifications.sendSimple( id, title, message, filter )
    local notif = CFCNotifications.new( id, "Text", true )
    notif:SetText( message )
    notif:SetTitle( title )
    notif:SetCloseable( true )
    notif:SetPriority( CFCNotifications.PRIORITY_LOW )
    notif:Send( filter )
end

function CFCNotifications.sendHint( id, title, message, filter )
    local notif = CFCNotifications.new( id, "TextAcknowledge", true )
    notif:SetText( message )
    notif:SetTitle( title )
    notif:SetCloseable( true )
    notif:Send( filter )
end

function CFCNotifications.sendImportantSimple( id, title, message, filter )
    local notif = CFCNotifications.new( id, "Text", true )
    notif:SetText( message )
    notif:SetTitle( title )
    notif:SetCloseable( false )
    notif:SetPriority( CFCNotifications.PRIORITY_MAX )
    notif:Send( filter )
end

if SERVER then
    local function plural( n )
        if n == 1 then return "" end
        return "s"
    end
    function CFCNotifications.startVote( id, question, time, options, cb )
        local votes = {}
        local ended = false
        local notif = CFCNotifications.new( id, "Buttons", true )
        notif:SetText( question )
        notif:SetAlwaysTiming( true )
        notif:SetDisplayTime( time or 30 )
        notif:SetTimed( true )

        local plyTotal = 0
        local plyCount = 0
        local voteCount = 0

        for k, v in pairs( options or {} ) do
            notif:AddButton( v, Color( 255, 255, 255 ), v )
        end

        local function endVote()
            ended = true
            local winners = {}
            local maxVote = 0
            for k, v in pairs( votes ) do
                if v > maxVote then
                    winners = { k }
                    maxVote = v
                elseif v == maxVote then
                    table.insert( winners, k )
                end
            end

            if #winners == 0 then
                CFCNotifications.sendSimple( id, "Vote results ( " .. voteCount .. " / " .. plyTotal .. " voted )",
                    "No-one voted! There is no winner." )
            else
                CFCNotifications.sendSimple( id, "Vote results ( " .. voteCount .. " / " .. plyTotal .. " voted )",
                    "Option" .. plural( #winners ) .. " \"" .. table.concat( winners, "\", \"" ) ..
                    "\" won with " .. maxVote .. " vote" .. plural( maxVote ) .. "." )
            end

            if cb then
                if #winners == 1 then
                    if not options then
                        winners[1] = winners[1] == "Yes"
                    end
                    cb( winners[1] )
                else
                    cb( winners )
                end
            end
        end

        timer.Create( "CFCNotifications_vote_" .. id, time + 5, 1, function()
            if ended then return end
            notif:Remove()
            timer.Simple( 1, endVote )
        end )

        function notif:OnButtonPressed( ply, option )
            if ended then return end
            if type( option ) == "boolean" then option = option and "Yes" or "No" end
            votes[option] = votes[option] or 0
            votes[option] = votes[option] + 1
            plyCount = plyCount + 1
            voteCount = voteCount + 1
            if plyCount == plyTotal then
                notif:Remove()
                timer.Simple( 1, endVote )
            end
        end

        function notif:OnClose( ply )
            if ended then return end
            plyCount = plyCount + 1
            if plyCount == plyTotal then
                notif:Remove()
                timer.Simple( 1, endVote )
            end
        end

        function notif:OnOpen( ply )
            plyTotal = plyTotal + 1
        end

        notif:Send()
    end
end