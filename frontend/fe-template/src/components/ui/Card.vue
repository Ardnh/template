<template>
  <div class="card">
    <div v-if="$slots.header" class="card-header">
      <slot name="header" />
    </div>
    <div class="card-body">
      <slot />
    </div>
    <div v-if="$slots.footer" class="card-footer">
      <slot name="footer" />
    </div>
  </div>
</template>

<style scoped>
.card {
  background: white;
  border-radius: 0.5rem;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
  overflow: hidden;
}

.card-header {
  padding: 1rem;
  border-bottom: 1px solid #e5e7eb;
  font-weight: 600;
}

.card-body {
  padding: 1rem;
}

.card-footer {
  padding: 1rem;
  border-top: 1px solid #e5e7eb;
  background: #f9fafb;
}
</style>
