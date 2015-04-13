cd ~/examples/miswhale/
openshift ex new-project miswhale --display-name="MisWhale" --description="MisWhale - Misfit" --admin=test-admin
osc process -n miswhale -f miswhale-template.json | osc create -n miswhale -f -


osc process -n miswhale -f miswhale-template.json | osc delete -n miswhale -f -
