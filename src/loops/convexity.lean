import analysis.convex.caratheodory
import analysis.convex.topology
import linear_algebra.affine_space.independent
import tactic.equiv_rw

noncomputable theory

/-!
# Convexity lemmas

This file gathers variations on Caratheodory's theorem for convex hulls.
-/

open set finset finite_dimensional
open_locale big_operators

section linear_algebra
open submodule
variables  {K : Type*}  [field K] {V : Type*} [add_comm_group V] [vector_space K V] -- [finite_dimensional K V] 
           {n : ℕ} {v : fin n → V} {ι : Type*}

lemma fintype.of_cardinal_lt {α : Type*} (h : cardinal.mk α < cardinal.omega) : fintype α :=
classical.choice $ cardinal.lt_omega_iff_fintype.mp h

protected lemma finite_dimensional.fintype [finite_dimensional K V] {v : ι → V} (hv : is_basis K v) : fintype ι :=
begin
  apply fintype.of_cardinal_lt,
  rw ← finite_dimensional.findim_eq_card_basis' hv,
  exact cardinal.nat_lt_omega _  
 end

/- -- useless here, but a big hole in the API
lemma finite_dimensional.linear_equiv_fin [finite_dimensional K V] : ((fin $ findim K V) → K) ≃ₗ[K] V :=
begin
  
  sorry
end -/

lemma linear_independent.rescale {v : ι → V} (h : linear_independent K v) {w : ι → K} (hw : ∀ i, w i ≠ 0) : linear_independent K (λ i, w i • v i) :=
begin
  rw linear_independent_iff' at *,
  intros s g hg i hi,
  simp_rw smul_smul at hg,
  suffices : g i *w i = 0,
  { have := mul_eq_zero.mp this,
    tauto },
  exact h s (λ i, g i * w i) hg i hi,
end

lemma submodule.mem_span_of_mem {R : Type*} [comm_ring R] {M : Type*} [add_comm_group M] [module R M] {s : set M}
  {x : M} (h : x ∈ s) : x ∈ span R s :=
subset_span h

lemma submodule.mem_span_range {R : Type*} [comm_ring R] {M : Type*} [add_comm_group M] [module R M] {ι : Type*}
  (f : ι → M) (i : ι) : f i ∈ span R (range f) :=
subset_span (mem_range_self i)

open submodule

lemma submodule.span_eq_of_subset {R M : Type*} [comm_ring R] [add_comm_group M] [module R M] {s t : set M}
  (h : s ⊆ span R t) (h' : t ⊆ span R s) : span R s = span R t :=
le_antisymm (span_le.mpr h) (span_le.mpr h')

lemma span_rescale {v : ι → V} {w : ι → K} (hw : ∀ i, w i ≠ 0) : span K (range $ λ i, w i • v i)  = span K (range v) :=
begin
  apply submodule.span_eq_of_subset,
  { rintros _ ⟨i, rfl⟩,
      exact smul_mem _ _ (mem_span_range v i) },
  { rintros _ ⟨i, rfl⟩,
     suffices : w i • v i ∈ span K (range $ λ i, w i • v i),
     { have fact : (w i)⁻¹ • w i • v i ∈ span K (range $ λ i, w i • v i) := smul_mem _ _ (mem_span_range _ i),
       simpa [smul_smul, hw i] using fact, },
     exact mem_span_range _ i }  
end

lemma is_basis.rescale {v : ι → V} (h : is_basis K v) {w : ι → K} (hw : ∀ i, w i ≠ 0) : is_basis K (λ i, w i • v i) :=
⟨h.1.rescale hw, by { rw span_rescale hw, exact h.2 }⟩

end linear_algebra

section affine

variables  {k : Type*}  [field k] {V : Type*} [add_comm_group V] [vector_space k V]
           {P : Type*} [affine_space k P]

-- This will turn out to be useless, but could still go to mathlib
lemma affine_independent_rescale {ι : Type*} {p : ι → P} (hp : affine_independent k p) {w : ι → k}
  (hw : ∀ i, w i ≠ 0) (i₀ : ι) : affine_independent k (λ i, (w i) • (p i -ᵥ p i₀) +ᵥ p i₀) :=
begin
  suffices : linear_independent k (λ (i : {x // x ≠ i₀}), w i • (p i -ᵥ p i₀)),
    by simpa [affine_independent_iff_linear_independent_vsub k _ i₀],
  rw affine_independent_iff_linear_independent_vsub k _ i₀ at hp,
  apply hp.rescale,
  tauto
end


end affine

section linear_algebra
variables {F : Type*} [add_comm_group F] [vector_space ℝ F] 

lemma caratheodory' {P : set F} {x : F} (h : x ∈ convex_hull P) : 
  ∃ (p₀ ∈ P) (n : ℕ) (v : fin n → F) (w : fin n → ℝ), 
    linear_independent ℝ v ∧
    (∀ i, w i ∈ (Ioc 0 1 : set ℝ)) ∧
    (∀ i, p₀ + v i ∈ P) ∧
    x = p₀ + ∑ i, w i • v i :=
sorry

end linear_algebra

open_locale topological_space

-- TODO : do a more general version using mem_nhds_iff_exists_Ioo_subset and a dense order
lemma real.exists_pos_of_mem_nhds_zero {s : set ℝ} (h : s ∈ (𝓝 (0 : ℝ))) : ∃ ε : ℝ, ε > 0 ∧ ε ∈ s :=
begin
  rcases metric.nhds_basis_ball.mem_iff.mp h with ⟨δ, δ_pos, hδ⟩,
  use [δ/2, by linarith],
  rw real.ball_eq_Ioo at hδ,
  apply hδ,
  simp ; split ; linarith
end

variables {F : Type*} [normed_group F] [normed_space ℝ F]  [finite_dimensional ℝ F]
local notation `d` := findim ℝ F

lemma eq_center_mass_basis_of_mem_convex_hull {P : set F} {x : F}
  (hP : is_open P)
  (h : x ∈ convex_hull P) : ∃ (p₀ : F) (v : fin d → F) (w : fin d → ℝ), 
  x = p₀ + ∑ i, w i • v i ∧ is_basis ℝ v ∧ (∀ i, w i ∈ (Icc 0 1 : set ℝ)) ∧ ∀ i, p₀ + v i ∈ P :=
begin
  rcases caratheodory' h with ⟨p₀, p₀_in, n, v, w, hv, hw, h_in, h⟩,
  use p₀,
  rcases exists_sum_is_basis hv with ⟨ι, v', hvv'⟩,
  letI : fintype ι := begin
    letI : fintype (fin n ⊕ ι) := finite_dimensional.fintype hvv',
    exact fintype.of_injective (sum.inr : ι → fin n ⊕ ι) (λ _ _, sum.inr.inj)
  end,
  rcases finite_dimensional.equiv_fin hvv' with ⟨g, hg⟩,
  obtain ⟨ε, ε_pos, hε⟩ : ∃ ε : ℝ, ε > 0 ∧ ∀ i, p₀ + ε • v' i ∈ P,
  { let f : ι → ℝ → F := λ i t, p₀ + t • v' i,
    have cont : ∀ i, continuous (f i),
    { intros i,
      exact continuous_const.add (continuous_id.smul continuous_const) },
    have : ∀ i, (f i) ⁻¹' P ∈ 𝓝 (0 : ℝ),
    { intros i,
      apply (cont i).continuous_at,
      apply is_open_iff_mem_nhds.mp hP,
      convert p₀_in,
      simp [f] },
    simpa using real.exists_pos_of_mem_nhds_zero (filter.Inter_mem_sets_of_fintype this) },
  let v'' := (λ i', ε • v' i'),
  refine ⟨sum.elim v v'' ∘ g, sum.elim w (λ i, 0) ∘ g, _, _, _, _⟩,
  { change x = p₀ + ∑ i, ((λ x, (sum.elim w (λ (i : ι), 0) x) • (sum.elim v v'' x)) ∘ g) i,
    rw [sum_equiv g, fintype.sum_sum_type],
    simp [h] },
  { suffices : is_basis ℝ (sum.elim v v''), from this.comp _ g.bijective,
    let s : fin n ⊕ ι → ℝ := sum.elim (λ i, 1) (λ i, ε),
    have hs : ∀ x, s x ≠ 0, by rintros ⟨x⟩ ; simp [s, ne_of_gt ε_pos],
    convert hvv'.rescale hs,
    ext ⟨x⟩ ; simp [s, v''] },
  { simp_rw mem_Ioc at hw,
    equiv_rw g,
    simp,
    split,
    intro i, split ; linarith [(hw i).1, (hw i).2],
    norm_num },
  { equiv_rw g,
    simp [h_in],
    exact hε },
end