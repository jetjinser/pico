package prose

import (
	"fmt"

	"git.sr.ht/~erock/pico/shared"
	"git.sr.ht/~erock/pico/wish/cms/config"
)

func NewConfigSite() *shared.ConfigSite {
	domain := shared.GetEnv("PROSE_DOMAIN", "prose.sh")
	email := shared.GetEnv("PROSE_EMAIL", "hello@prose.sh")
	subdomains := shared.GetEnv("PROSE_SUBDOMAINS", "0")
	customdomains := shared.GetEnv("PROSE_CUSTOMDOMAINS", "0")
	port := shared.GetEnv("PROSE_WEB_PORT", "3000")
	protocol := shared.GetEnv("PROSE_PROTOCOL", "https")
	allowRegister := shared.GetEnv("PROSE_ALLOW_REGISTER", "1")
	storageDir := shared.GetEnv("IMGS_STORAGE_DIR", ".storage")
	minioURL := shared.GetEnv("MINIO_URL", "")
	minioUser := shared.GetEnv("MINIO_ROOT_USER", "")
	minioPass := shared.GetEnv("MINIO_ROOT_PASSWORD", "")
	dbURL := shared.GetEnv("DATABASE_URL", "")
	subdomainsEnabled := false
	if subdomains == "1" {
		subdomainsEnabled = true
	}

	customdomainsEnabled := false
	if customdomains == "1" {
		customdomainsEnabled = true
	}

	intro := "To get started, enter a username.\n"
	intro += "Then create a folder locally (e.g. ~/blog).\n"
	intro += "Then write your post in markdown files (e.g. hello-world.md).\n"
	intro += "Finally, send your files to us:\n\n"
	intro += fmt.Sprintf("scp ~/blog/*.md %s:/", domain)

	return &shared.ConfigSite{
		SubdomainsEnabled:    subdomainsEnabled,
		CustomdomainsEnabled: customdomainsEnabled,
		ConfigCms: config.ConfigCms{
			Domain:        domain,
			Email:         email,
			Port:          port,
			Protocol:      protocol,
			DbURL:         dbURL,
			StorageDir:    storageDir,
			MinioURL:      minioURL,
			MinioUser:     minioUser,
			MinioPass:     minioPass,
			Description:   "a blog platform for hackers.",
			IntroText:     intro,
			Space:         "prose",
			AllowedExt:    []string{".md"},
			HiddenPosts:   []string{"_readme.md", "_styles.css", "_footer.md"},
			Logger:        shared.CreateLogger(),
			AllowRegister: allowRegister == "1",
		},
	}
}
