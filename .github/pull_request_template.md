## Description

Please include a summary of the changes i.e. .NET version updates, libraries patched, or issues added to the policy file.

### Checklist:

- [ ] I have ensured the Defra version in the **JOB.env** file matches that in the **Dockerfile**
- [ ] I have ensured the .NET versions and digests in the **image-matrix.json** match the **Dockerfile** and the table in the **README.md**
- [ ] Any new entry in **vulnerability-policy.yml** has a reason, an owner and a review date
- [ ] I have removed any expired entries, or entries no longer matching anything, from **vulnerability-policy.yml**
