foundryPkg:
{
  username ? "",
  password ? "",
  passwordFile ? "",
  installDir ? "/etc/foundryvtt",
  majorVersion ? "13",
  build ? "350",
  ...
}:
foundryPkg.overrideAttrs (old:
  let
    filename = "${majorVersion}.${build}";
  in
  {
    prePhases = old.prePhases or [] ++ [''
      # Get tokens from main webpage...
      # 1. csrftoken cookie -> /tmp/cookies.txt
      # 2. csrfmiddlewaretoken value
      CSRF_TOKEN=$(
        curl --cookie-jar /tmp/cookies.txt "https://foundryvtt.com/" --referer "https://foundryvtt.com/" "DNT: \"1\"" -H "Upgrade-Insecure-Requests: \"1\"")
        | grep -Po "csrfmiddlewaretoken\"\s*value=\"\K[^\"]+"
        | head -1
      )

      # Get user password from provided inputs
      PASSWORD=$(( ${password} == "" ? cat ${passwordFile} : ${password} ))

      # Construct form data from retrieved token and provided auth
      DATA="username=${username}&password=$PASSWORD&csrfmiddlewaretoken=$CSRF_TOKEN&next=%2F&login="

      # Get sessionid token -> /tmp/cookies.txt
      curl -L --cookie /tmp/cookies.txt --cookie-jar /tmp/cookies.txt "https://foundryvtt.com/auth/login/ -H "Content-Type: application/x-www-form-urlencoded" -H "DNT: \"1\"" -H "Upgrade-Insecure-Requests: \"1\"" --data $DATA --referer "https://foundryvtt.com/"

      # Download the specified build
      curl -L --cookie /tmp/cookies.txt "Https://foundryvtt.com/releases/download?build=${build}&platform=linux" -o ./${filename}

      # Add to store and prevent garbage collection
      STORE_PATH=$(nix-store --add-fixed sha256 ${filename})
      mkdir -p ${installDir}
      nix-store --add-root ${installDir}/${filename} -r $STORE_PATH

      # Clean up
      rm /tmp/cookies.txt
    ''];
  }
)
