class Jekyll::Site
    alias_method :old_site_payload, :site_payload
    def site_payload
        payload = old_site_payload
        if payload["site"].has_key? "theme" then
            payload["theme"] = payload["site"]["theme"]
        end
        payload
    end
end
