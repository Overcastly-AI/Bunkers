/**
 * THE REPOSITORY FACTORY — one call, one seam.
 *
 * Components import `getRepository()` and nothing else from this directory.
 * They never construct an implementation, never read an environment variable,
 * and never branch on `repo.kind`. That is the whole of the contract, and it is
 * what makes the eventual swap a one-line change here rather than a sweep
 * through the component tree.
 *
 * SELECTION. The seed implementation is the default and stays the default until
 * BOTH Supabase variables are present AND `BUNKERS_DATA_SOURCE=supabase` is set
 * explicitly. Two independent conditions, deliberately: a stray environment
 * variable in a preview deployment must not silently switch a register with
 * zero candidates onto a live database whose RLS posture has not been verified
 * (D-008). Turning it on is a decision someone makes, not an accident of
 * configuration.
 */

import { SeedRepository } from "./seed-repository";
import { SupabaseRepository } from "./supabase-repository";
import type { Repository } from "./types";

export type {
  NotLocatableRow,
  RegisterFilter,
  Repository,
  ViewportRequest,
  ViewportResult,
} from "./types";
export { SeedRepository } from "./seed-repository";
export { SupabaseRepository } from "./supabase-repository";
export {
  CORPUS_CATALOGUED,
  CORPUS_TRANSCRIBED,
  HOSTS_IN_ACCESS_SCHEDULE,
} from "./curated";

let instance: Repository | null = null;

export function getRepository(): Repository {
  if (instance) return instance;

  const url = process.env["NEXT_PUBLIC_SUPABASE_URL"];
  const anonKey = process.env["NEXT_PUBLIC_SUPABASE_ANON_KEY"];
  const optIn = process.env["BUNKERS_DATA_SOURCE"] === "supabase";

  instance =
    optIn && url && anonKey
      ? new SupabaseRepository({ url, anonKey, schema: "api" })
      : new SeedRepository();

  return instance;
}

/** Tests and scripts only. Never call this from a component. */
export function setRepository(repo: Repository | null): void {
  instance = repo;
}
