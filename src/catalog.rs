//! The route catalog recovered from the 9.6.30 APK, embedded at build time.

use std::collections::HashMap;
use std::sync::OnceLock;

use serde::{Deserialize, Serialize};

/// One canonical endpoint and the parameter keys recovered for it.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RouteInfo {
    pub route: String,
    #[serde(default)]
    pub params: Vec<String>,
    pub group: String,
    #[serde(default)]
    pub inferred: bool,
}

static RAW: &str = include_str!("../assets/routes.json");

const PREFIXES: [&str; 6] = ["api/", "weapi/", "eapi/", "xeapi/", "neapi/", "linuxapi/"];

pub struct Catalog {
    routes: HashMap<String, RouteInfo>,
    groups: HashMap<String, usize>,
}

impl Catalog {
    /// Parse the embedded catalog once per process.
    pub fn global() -> &'static Catalog {
        static CATALOG: OnceLock<Catalog> = OnceLock::new();
        CATALOG.get_or_init(|| Catalog::from_json(RAW).expect("embedded route catalog is valid"))
    }

    pub fn from_json(raw: &str) -> Result<Self, serde_json::Error> {
        let entries: Vec<RouteInfo> = serde_json::from_str(raw)?;
        let mut routes = HashMap::with_capacity(entries.len());
        let mut groups: HashMap<String, usize> = HashMap::new();
        for entry in entries {
            *groups.entry(entry.group.clone()).or_default() += 1;
            routes.insert(entry.route.clone(), entry);
        }
        Ok(Self { routes, groups })
    }

    pub fn len(&self) -> usize {
        self.routes.len()
    }

    pub fn is_empty(&self) -> bool {
        self.routes.is_empty()
    }

    pub fn group_count(&self) -> usize {
        self.groups.len()
    }

    /// Look a route up the way the Python/Rust clients do: canonicalize any
    /// spelling, then accept `v1/`…`v9/` prefixed forms.
    pub fn get(&self, spelling: &str) -> Option<&RouteInfo> {
        let canonical = canonical(spelling);
        if let Some(found) = self.routes.get(&canonical) {
            return Some(found);
        }
        for version in 1..=9 {
            if let Some(found) = self.routes.get(&format!("v{version}/{canonical}")) {
                return Some(found);
            }
        }
        None
    }

    /// Case-insensitive substring search, optionally restricted to a group.
    pub fn find(&self, needle: &str, group: Option<&str>) -> Vec<&RouteInfo> {
        let needle = needle.to_lowercase();
        let mut out: Vec<&RouteInfo> = self
            .routes
            .values()
            .filter(|e| needle.is_empty() || e.route.to_lowercase().contains(&needle))
            .filter(|e| group.is_none_or(|g| e.group == g))
            .collect();
        out.sort_by(|a, b| a.route.cmp(&b.route));
        out
    }
}

/// Strip URL scheme, query, fragment and transport prefixes from a route.
pub fn canonical(route: &str) -> String {
    let mut path = route;
    if let Some((_, rest)) = path.split_once("://") {
        path = rest.split_once('/').map(|(_, p)| p).unwrap_or("");
    }
    let path = path.split(['?', '#']).next().unwrap_or("");
    let mut path = path.trim_matches('/');
    for prefix in PREFIXES {
        if let Some(rest) = path.strip_prefix(prefix) {
            path = rest;
            break;
        }
    }
    path.trim_matches('/').to_string()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn catalog_matches_the_recovered_one() {
        let catalog = Catalog::global();
        assert_eq!(catalog.len(), 1293);
        assert_eq!(catalog.group_count(), 150);
    }

    #[test]
    fn lookup_tolerates_prefixes_and_versions() {
        let catalog = Catalog::global();
        assert_eq!(catalog.get("song/detail").unwrap().route, "v3/song/detail");
        assert_eq!(catalog.get("/api/song/detail").unwrap().route, "v3/song/detail");
        assert!(catalog.get("definitely/not/a/route").is_none());
    }

    #[test]
    fn canonical_strips_scheme_and_query() {
        assert_eq!(canonical("eapi/song/detail?x=1"), "song/detail");
        assert_eq!(
            canonical("https://music.163.com/weapi/v3/song/detail"),
            "v3/song/detail"
        );
    }
}
