const { execSync } = require('child_process');

function ghApi(endpoint, params = {}) {
    // Construct query string for GET request
    const queryString = new URLSearchParams(params).toString();
    const fullUrl = queryString ? `${endpoint}?${queryString}` : endpoint;
    
    const cmd = `gh api "${fullUrl}"`;
    
    try {
        const result = execSync(cmd, { encoding: 'utf8' });
        return JSON.parse(result);
    } catch (e) {
        console.error(`Error calling ${fullUrl}:`, e.message);
        process.exit(1);
    }
}

async function main() {
    const owner = 'EasyTier';
    const repo = 'EasyTier';
    const workflow_id = 'core.yml';

    console.log("1. Get latest main push run...");
    const mainRuns = ghApi(`/repos/${owner}/${repo}/actions/workflows/${workflow_id}/runs`, {
        branch: 'main',
        event: 'push',
        status: 'success',
        per_page: 1
    });

    if (mainRuns.total_count === 0) {
        console.log('No successful runs found on main branch.');
        return;
    }

    const mainRun = mainRuns.workflow_runs[0];
    const mainRunId = String(mainRun.id);
    const treeId = mainRun.head_commit.tree_id;

    console.log(`Latest main run: ${mainRunId}, Tree ID: ${treeId}`);

    // Check artifacts for main run
    console.log(`Checking artifacts for main run ${mainRunId}...`);
    const mainArtifacts = ghApi(`/repos/${owner}/${repo}/actions/runs/${mainRunId}/artifacts`, {
        per_page: 1
    });

    let artifactRunId = '';

    if (mainArtifacts.total_count > 0) {
        console.log(`Main run ${mainRunId} has artifacts.`);
        artifactRunId = mainRunId;
    } else {
        console.log(`Main run ${mainRunId} has no artifacts. Searching for duplicate runs with Tree ID ${treeId}...`);

        // Search for other runs with same tree_id
        const recentRuns = ghApi(`/repos/${owner}/${repo}/actions/workflows/${workflow_id}/runs`, {
            status: 'success',
            per_page: 50
        });

        for (const run of recentRuns.workflow_runs) {
            // Skip the main run itself
            if (String(run.id) === mainRunId) continue;

            if (run.head_commit.tree_id === treeId) {
                console.log(`Checking candidate run ${run.id} (Branch: ${run.head_branch}, Event: ${run.event})...`);
                
                const artifacts = ghApi(`/repos/${owner}/${repo}/actions/runs/${run.id}/artifacts`, {
                    per_page: 1
                });

                if (artifacts.total_count > 0) {
                    console.log(`Found artifacts in run ${run.id}`);
                    artifactRunId = String(run.id);
                    break;
                } else {
                    console.log(`Candidate run ${run.id} has no artifacts.`);
                }
            }
        }
    }

    console.log('-'.repeat(20));
    console.log(`RESULT:`);
    console.log(`LATEST_RUN_ID (for state file): ${mainRunId}`);
    console.log(`ARTIFACT_RUN_ID (for download): ${artifactRunId}`);
    
    if (!artifactRunId) {
        console.log("FAILURE: No artifacts found matching the latest main version.");
    }
}

main();
