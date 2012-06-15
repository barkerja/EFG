class UserImporter < BaseImporter
  self.csv_path = Rails.root.join('import_data/users.csv')
  self.klass = User

  def self.field_mapping
    {
      'USER_ID'              => :legacy_id,
      'LENDER_OID'           => :legacy_lender_id,
      'PASSWORD'             => :encrypted_password,
      'CREATION_TIME'        => :created_at,
      'LAST_MOD_TIME'        => :updated_at,
      'LAST_LOGIN_TIME'      => :last_sign_in_at,
      'VERSION'              => :version,
      'FIRST_NAME'           => :first_name,
      'LAST_NAME'            => :last_name,
      'DISABLED'             => :disabled,
      'MEMORABLE_NAME'       => :memorable_name,
      'MEMORABLE_PLACE'      => :memorable_place,
      'MEMORABLE_YEAR'       => :memorable_year,
      'LOGIN_FAILURES'       => :login_failures,
      'PASSWORD_CHANGE_TIME' => :password_changed_at,
      'LOCKED'               => :locked,
      'AR_TIMESTAMP'         => :ar_timestamp,
      'AR_INSERT_TIMESTAMP'  => :ar_insert_timestamp,
      'EMAIL_ADDRESS'        => :email,
      'CREATOR_USER_ID'      => :created_by_legacy_id,
      'CONFIRM_T_AND_C'      => :confirm_t_and_c,
      'MODIFIED_BY'          => :modified_by_legacy_id,
      'KNOWLEDGE_RESOURCE'   => :knowledge_resource
    }
  end

  def attributes
    row.inject({}) do |memo, (field_name, value)|
      value = case field_name
      when 'EMAIL_ADDRESS'
        # Obfuscated data all has the same email address.
        nil
      else
        value
      end

      memo[self.class.field_mapping[field_name]] = value
      memo
    end
  end

  private

  def self.after_import
    klass.find_each do |user|
      user.created_by  = User.find_by_legacy_id(user.created_by_legacy_id)
      user.modified_by = User.find_by_legacy_id(user.modified_by_legacy_id)
      user.lender      = Lender.find_by_legacy_id(user.legacy_lender_id) unless user.legacy_lender_id.blank?

      user.save!(validate: false)
    end
  end
end
