{
  vault = {
    name = "hermes-credential-vault";

    settings = {
      unmatched_host_policy = "passthrough";
    };

    # Public values may be committed here. Environment values name variables
    # supplied to the reconciliation unit through its protected EnvironmentFile.
    credentials = {
      static.GITLAB_GIT_USERNAME = "oauth2";
      environment.GITLAB_TOKEN = "GITLAB_TOKEN";
    };

    services = [
      # These more-specific rules deliberately inject no credential. They win
      # over gitlab-api and prevent the API token from minting credentials that
      # could be used outside Agent Vault.
      {
        name = "gitlab-block-user-keys";
        host = "gitlab.com/api/v4/user/keys*";
        auth.type = "passthrough";
      }
      {
        name = "gitlab-block-user-gpg-keys";
        host = "gitlab.com/api/v4/user/gpg_keys*";
        auth.type = "passthrough";
      }
      {
        name = "gitlab-block-personal-access-tokens";
        host = "gitlab.com/api/v4/personal_access_tokens*";
        auth.type = "passthrough";
      }
      {
        name = "gitlab-block-project-access-tokens";
        host = "gitlab.com/api/v4/projects/*/access_tokens*";
        auth.type = "passthrough";
      }
      {
        name = "gitlab-block-group-access-tokens";
        host = "gitlab.com/api/v4/groups/*/access_tokens*";
        auth.type = "passthrough";
      }
      {
        name = "gitlab-block-project-deploy-keys";
        host = "gitlab.com/api/v4/projects/*/deploy_keys*";
        auth.type = "passthrough";
      }
      {
        name = "gitlab-block-project-deploy-tokens";
        host = "gitlab.com/api/v4/projects/*/deploy_tokens*";
        auth.type = "passthrough";
      }
      {
        name = "gitlab-block-group-deploy-tokens";
        host = "gitlab.com/api/v4/groups/*/deploy_tokens*";
        auth.type = "passthrough";
      }

      {
        name = "gitlab-api";
        host = "gitlab.com/api/v4/*";
        auth = {
          type = "bearer";
          token = "GITLAB_TOKEN";
        };
      }
      {
        name = "gitlab-git";
        host = "gitlab.com/*.git/*";
        auth = {
          type = "basic";
          username = "GITLAB_GIT_USERNAME";
          password = "GITLAB_TOKEN";
        };
      }
    ];
  };

  agent = {
    name = "hermes";
    role = "no-access"; # can't access/manage secrets
    vaultRole = "proxy"; # can have requests proxied with injected credentials
  };
}
