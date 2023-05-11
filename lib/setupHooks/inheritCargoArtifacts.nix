{ makeSetupHook
, rsync
}:

makeSetupHook
{
  name = "inheritCargoArtifactsHook";
  propagatedBuildInputs = [ rsync ];
} ./inheritCargoArtifactsHook.sh

