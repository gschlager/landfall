# frozen_string_literal: true

# name: landfall
# about: Helps admins migrate communities into Discourse — letting members keep logging in with their old username and password after an import.
# meta_topic_id: TODO
# version: 0.0.1
# authors: Gerhard Schlager
# url: https://github.com/gschlager/discourse-migrations
# required_version: 2.7.0

# Discourse uses pbkdf2 natively and no longer ships bcrypt, so the plugin declares
# it for verifying legacy bcrypt password hashes during a migration.
gem "bcrypt", "3.1.22"

enabled_site_setting :landfall_enabled

module ::Landfall
  PLUGIN_NAME = "landfall"
end

require_relative "lib/landfall/engine"

after_initialize do
  require_relative "lib/landfall/legacy_password_verifier"
  require_relative "lib/landfall/login_decision"
  require_relative "lib/landfall/old_username_login"
  require_relative "lib/landfall/user_confirm_password_extension"
  require_relative "lib/landfall/session_controller_extension"

  reloadable_patch do
    User.has_one :landfall_migrated_password,
                 class_name: "Landfall::MigratedPassword",
                 dependent: :destroy
    User.has_many :landfall_old_usernames, class_name: "Landfall::OldUsername", dependent: :destroy

    User.prepend(Landfall::UserConfirmPasswordExtension)
    SessionController.prepend(Landfall::SessionControllerExtension)
  end
end
