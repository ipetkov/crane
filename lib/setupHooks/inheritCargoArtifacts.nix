{ makeSetupHook
, rsync
}:

makeSetupHook
{
  name = "inheritCargoArtifactsHook";
} ./inheritCargoArtifactsHook.sh

