import assert from 'assert';
import { createSelector } from 'reselect';
import { plugins } from '@bpanel/bpanel-utils';

const { comparePlugins } = plugins;

const getMetadataList = state => Object.values(state.pluginMetadata);
const getSidebarItems = state => state.nav.sidebar;

/* Sort plugin metadata (by order and name) and insert and
 * sort children after parents
 * @param {Array{}} pluginMeta - unsorted array of plugin Metadata
 * @returns {Array{}} plugins - returns an array of sorted metadata objects
 */
export const sortPluginMetadata = (pluginMeta = []) => {
  assert(Array.isArray(pluginMeta), 'Must pass array of metadata');
  const subItems = new Map();

  const sortedPluginMetadata = pluginMeta
    .filter(plugin => {
      if (plugin.parent) {
        // if it has a parent then add it to corresponding array in subItems map
        // this is so that we can get all subItems and then sort later
        const { parent } = plugin;
        if (!subItems.has(parent)) {
          subItems.set(parent, [plugin]);
        } else {
          const children = subItems.get(parent);
          children.push(plugin);
          subItems.set(parent, children);
        }
        // don't return to array of top level items
        return false;
      } else {
        // only returning an array of the parents
        return true;
      }
    })
    .sort(comparePlugins);

  subItems.forEach((children, parent) => {
    const index = sortedPluginMetadata.findIndex(
      plugin => parent === plugin.name
    );
    children.sort(comparePlugins);
    sortedPluginMetadata.splice(index + 1, 0, ...children);
  });

  return sortedPluginMetadata;
};

/* Update list of plugin metadata (or nav objects) to have properly
 * formatted, nested paths
 * e.g. { name: 'child', parent: 'parent' } becomes
 * { name: 'child', parent: 'parent', pathName: 'parent/child'}
 * @param {Array{}} metadata - Array of plugin metadata objects
 * @returns {Array{}} plugins - returns an array of metadata w/ updated paths
 */
export function getNestedPaths(metadata) {
  assert(Array.isArray(metadata), 'Must pass array of metadata');
  return metadata.reduce((updated, plugin) => {
    if (plugin.parent) {
      // if this plugin is a child then update its pathName property
      // to nest behind the parent
      const parentIndex = metadata.findIndex(
        item => item.name === plugin.parent
      );

      const parent = metadata[parentIndex];
      // eslint-disable-next-line no-console
      console.assert(
        parent,
        `Parent ${plugin.parent} could not be found for child ${plugin.name}`
      );
      // get parent path, if none, use name
      const parentPath = parent.pathName ? parent.pathName : parent.name;

      // get plugin path, if none, use name
      let pathName = plugin.pathName ? plugin.pathName : plugin.name;

      // sanitize of any other uri constructions like other nested paths
      pathName = pathName.slice(pathName.lastIndexOf('/') + 1);

      // make nested path
      pathName = `${parentPath}/${pathName}`;
      plugin.pathName = pathName;
    }
    updated.push(plugin);
    return updated;
  }, []);
}

/* Get plugin metadata list w/ unique pathNames
 * @param {Object{}} metadata - object of plugin metadata objects
 * @returns {Array{}} plugins - returns an array of metadata objects with unique paths
 */
export const getUniquePaths = metadata => {
  assert(Array.isArray(metadata), 'Must pass array of metadata');
  const paths = new Set();
  const names = new Set();

  return metadata.reduce((acc, plugin) => {
    const { pathName, name, displayName: _displayName } = plugin;
    if (pathName) {
      let path = pathName;

      if (paths.has(path)) {
        // find unique suffix by incrementing counter
        let counter = 1;
        while (paths.has(`${path}-${counter}`)) {
          counter++;
        }
        path = `${path}-${counter}`;
      }

      paths.add(path);
      // set the metadata to the unique path
      plugin.pathName = path;
    }

    // get unique displayName using same mechanism
    let displayName = _displayName ? _displayName : name;
    if (names.has(displayName)) {
      let counter = 1;
      while (names.has(`${displayName}-${counter}`)) {
        counter++;
      }
      displayName = `${displayName}-${counter}`;
    }
    names.add(displayName);
    plugin.displayName = displayName;

    acc.push(plugin);
    return acc;
  }, []);
};

export function getNavItems(metadata = []) {
  assert(Array.isArray(metadata), 'Must pass array to getNavItems');
  return metadata.filter(plugin => plugin.nav || plugin.sidebar);
}

// Properly compose metadata for navigation
// sort list of metadata -> compose nested paths -> make paths unique
function composeNavItems(_navItems = []) {
  assert(Array.isArray(_navItems), 'Must pass array to composeNavItems');
  let navItems = getNavItems(_navItems);
  navItems = sortPluginMetadata(navItems);
  navItems = getNestedPaths(navItems);
  navItems = getUniquePaths(navItems);
  return navItems;
}

// selectors for converting pluginMetadata to nav list
export const sortedNavItems = createSelector(getMetadataList, composeNavItems);

// selector for ordering and composing sidebar navigation items
export const sortedSidebarItems = createSelector(
  getSidebarItems,
  composeNavItems
);

// Useful selector for the Panel which just needs to match names to paths
export const uniquePathsByName = createSelector(getMetadataList, metadata => {
  const paths = {};
  metadata
    .filter(plugin => plugin.pathName)
    .forEach(({ name, pathName }) => (paths[name] = pathName));
  return paths;
});

export default {
  sortedNavItems,
  uniquePathsByName,
  sortedSidebarItems
};
